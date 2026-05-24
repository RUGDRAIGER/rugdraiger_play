package com.rugdraiger.rugdraiger_player

import android.net.Uri
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.InputStream
import kotlin.math.min

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rugdraiger/artwork",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractArtwork" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_PATH", "Path is empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val artwork = extractArtworkFromPath(path)
                            runOnUiThread {
                                result.success(artwork)
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("EXTRACT_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rugdraiger/widget",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getArtworkContentUri" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("INVALID_PATH", "Path is empty", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(path)
                        if (!file.exists()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file,
                        )
                        grantUriPermission(
                            applicationContext.packageName,
                            uri,
                            android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION,
                        )
                        result.success(uri.toString())
                    } catch (e: Exception) {
                        result.error("URI_ERROR", e.message, null)
                    }
                }

                "updateWidget" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?>
                    if (args == null) {
                        result.error("INVALID_ARGS", "Missing widget args", null)
                        return@setMethodCallHandler
                    }
                    WidgetHelper.saveState(this, args)
                    PlayerWidgetProvider.updateAll(this)
                    result.success(null)
                }

                "clearWidget" -> {
                    WidgetHelper.clearState(this)
                    PlayerWidgetProvider.updateAll(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun extractArtworkFromPath(path: String): ByteArray? {
        return if (path.startsWith("content://")) {
            contentResolver.openInputStream(Uri.parse(path))?.use { stream ->
                extractArtworkFromStream(stream, null)
            }
        } else {
            val file = File(path.removePrefix("file://"))
            if (!file.exists()) return null
            file.inputStream().use { stream ->
                extractArtworkFromStream(stream, file.length())
            }
        }
    }

    private fun extractArtworkFromStream(stream: InputStream, fileSize: Long?): ByteArray? {
        val maxFullRead = 5L * 1024L * 1024L
        val chunkSize = 512 * 1024

        val data = if (fileSize != null && fileSize > maxFullRead) {
            readHeadAndTail(stream, fileSize, chunkSize)
        } else {
            stream.readBytes()
        }

        if (data.isEmpty()) return null

        extractFromId3(data)?.let { return it }
        return scanForImage(data)
    }

    private fun readHeadAndTail(stream: InputStream, fileSize: Long, chunkSize: Int): ByteArray {
        val headSize = min(chunkSize.toLong(), fileSize).toInt()
        val head = ByteArray(headSize)
        var read = stream.read(head)
        if (read < headSize && read > 0) {
            return head.copyOf(read)
        }

        val tailSize = min(chunkSize.toLong(), fileSize).toInt()
        val skip = fileSize - tailSize
        if (skip > headSize) {
            stream.skip(skip - headSize)
        }

        val tail = ByteArray(tailSize)
        read = stream.read(tail)
        val tailUsed = if (read > 0) read else 0

        return head + tail.copyOf(tailUsed)
    }

    private fun extractFromId3(data: ByteArray): ByteArray? {
        if (data.size < 10) return null
        if (data[0] != 'I'.code.toByte() || data[1] != 'D'.code.toByte() || data[2] != '3'.code.toByte()) {
            return null
        }

        val versionMajor = data[3]
        val versionMinor = data[4]
        val tagSize = syncSafeInt(data.copyOfRange(6, 10))
        val isV24 = versionMajor == 4.toByte() && versionMinor == 0.toByte()
        val isV22 = versionMajor == 2.toByte()

        var pos = 10
        val end = min(10 + tagSize, data.size)

        while ((pos + if (isV22) 6 else 10) <= end) {
            val frameId = if (isV22) {
                String(data.copyOfRange(pos, pos + 3), Charsets.ISO_8859_1)
            } else {
                String(data.copyOfRange(pos, pos + 4), Charsets.ISO_8859_1)
            }

            if (frameId.replace("\u0000", "").isEmpty()) break

            val frameSize = if (isV22) {
                ((data[pos + 3].toInt() and 0xFF) shl 16) or
                    ((data[pos + 4].toInt() and 0xFF) shl 8) or
                    (data[pos + 5].toInt() and 0xFF)
            } else if (isV24) {
                syncSafeInt(data.copyOfRange(pos + 4, pos + 8))
            } else {
                int32(data.copyOfRange(pos + 4, pos + 8))
            }

            pos += if (isV22) 6 else 10
            if (frameSize <= 0 || pos + frameSize > data.size) break

            if (frameId == "APIC" || frameId == "PIC") {
                val frame = data.copyOfRange(pos, pos + frameSize)
                parseApicFrame(frame, isV22)?.let { return it }
            }

            pos += frameSize
        }

        return null
    }

    private fun parseApicFrame(frame: ByteArray, isV22: Boolean): ByteArray? {
        if (frame.isEmpty()) return null

        var offset = if (isV22) 1 else 1
        if (!isV22) {
            offset = skipNullTerminated(frame, offset)
            if (offset >= frame.size) return null
            offset += 1
            offset = skipNullTerminated(frame, offset)
        } else {
            offset += 3
            if (offset >= frame.size) return null
            offset += 1
            offset = skipNullTerminated(frame, offset)
        }

        if (offset >= frame.size) return null
        return frame.copyOfRange(offset, frame.size)
    }

    private fun skipNullTerminated(data: ByteArray, start: Int): Int {
        var i = start
        while (i < data.size && data[i] != 0.toByte()) i++
        return i + 1
    }

    private fun scanForImage(data: ByteArray): ByteArray? {
        var best: ByteArray? = null
        var bestSize = 0

        largestJpeg(data)?.let {
            if (it.size > bestSize) {
                best = it
                bestSize = it.size
            }
        }

        largestPng(data)?.let {
            if (it.size > bestSize) {
                best = it
                bestSize = it.size
            }
        }

        return if (bestSize >= 1024) best else null
    }

    private fun largestJpeg(data: ByteArray): ByteArray? {
        var best: ByteArray? = null
        var bestSize = 0
        var start = 0

        while (start < data.size - 3) {
            val idx = indexOf(data, byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte()), start)
            if (idx < 0) break

            val endIdx = indexOf(data, byteArrayOf(0xFF.toByte(), 0xD9.toByte()), idx + 3)
            if (endIdx < 0) break

            val length = endIdx - idx + 2
            if (length > bestSize && length >= 1024) {
                val candidate = data.copyOfRange(idx, endIdx + 2)
                if (isValidJpeg(candidate)) {
                    best = candidate
                    bestSize = length
                }
            }
            start = endIdx + 2
        }

        return best
    }

    private fun largestPng(data: ByteArray): ByteArray? {
        val signature = byteArrayOf(
            0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        )
        val idx = indexOf(data, signature, 0)
        if (idx < 0) return null

        var pos = idx + 8
        while (pos + 12 <= data.size) {
            val chunkLen = int32(data.copyOfRange(pos, pos + 4))
            val chunkType = String(data.copyOfRange(pos + 4, pos + 8), Charsets.US_ASCII)
            pos += 8 + chunkLen + 4
            if (chunkType == "IEND") {
                val total = pos - idx
                return if (total >= 1024) data.copyOfRange(idx, pos) else null
            }
            if (chunkLen < 0 || pos > data.size) return null
        }

        return null
    }

    private fun indexOf(data: ByteArray, pattern: ByteArray, start: Int): Int {
        if (pattern.isEmpty() || start >= data.size) return -1
        outer@ for (i in start..data.size - pattern.size) {
            for (j in pattern.indices) {
                if (data[i + j] != pattern[j]) continue@outer
            }
            return i
        }
        return -1
    }

    private fun syncSafeInt(bytes: ByteArray): Int =
        ((bytes[0].toInt() and 0x7F) shl 21) or
            ((bytes[1].toInt() and 0x7F) shl 14) or
            ((bytes[2].toInt() and 0x7F) shl 7) or
            (bytes[3].toInt() and 0x7F)

    private fun isValidJpeg(data: ByteArray): Boolean {
        if (data.size < 10) return false
        if (data[0] != 0xFF.toByte() || data[1] != 0xD8.toByte() || data[2] != 0xFF.toByte()) {
            return false
        }
        if (data[data.size - 2] != 0xFF.toByte() || data[data.size - 1] != 0xD9.toByte()) {
            return false
        }

        val marker = data[3].toInt() and 0xFF
        val validMarkers = setOf(0xC0, 0xC1, 0xC2, 0xC4, 0xDB, 0xDD, 0xE0, 0xE1, 0xFE)
        return marker in validMarkers
    }

    private fun int32(bytes: ByteArray): Int =
        ((bytes[0].toInt() and 0xFF) shl 24) or
            ((bytes[1].toInt() and 0xFF) shl 16) or
            ((bytes[2].toInt() and 0xFF) shl 8) or
            (bytes[3].toInt() and 0xFF)
}
