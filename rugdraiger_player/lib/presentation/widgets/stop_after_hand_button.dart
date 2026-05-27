import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/stop_after_service.dart';

class StopAfterHandButton extends StatefulWidget {
  final int songId;
  final double size;

  const StopAfterHandButton({super.key, required this.songId, this.size = 20});

  @override
  State<StopAfterHandButton> createState() => _StopAfterHandButtonState();
}

class _StopAfterHandButtonState extends State<StopAfterHandButton> {
  @override
  Widget build(BuildContext context) {
    final active = StopAfterService.instance.isEnabled(widget.songId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => StopAfterService.instance.toggle(widget.songId)),
        child: Container(
          width: widget.size + 10,
          height: widget.size + 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.accentIntense : AppColors.borderSubtle,
              width: active ? 2 : 1,
            ),
            color: active ? AppColors.accent.withValues(alpha: 0.35) : Colors.transparent,
            boxShadow: active
                ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.55), blurRadius: 12)]
                : null,
          ),
          child: Icon(
            Icons.pan_tool_alt_rounded,
            size: widget.size,
            color: active ? AppColors.accentIntense : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
