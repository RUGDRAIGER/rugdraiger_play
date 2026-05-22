import { APP_ICONS } from '../../constants/appBranding'

interface Props {
  size?: number
  borderRadius?: number
  className?: string
  style?: React.CSSProperties
}

export function AppIcon({ size = 40, borderRadius = 10, className, style }: Props) {
  return (
    <img
      src={APP_ICONS.app}
      alt="Rugdraiger Play"
      className={className}
      width={size}
      height={size}
      style={{
        width: size,
        height: size,
        borderRadius,
        objectFit: 'contain',
        flexShrink: 0,
        ...style,
      }}
    />
  )
}
