---
name: Rugdraiger Player Design System
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1b1b1b'
  surface-container: '#1f1f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353535'
  on-surface: '#e2e2e2'
  on-surface-variant: '#ebbbb4'
  inverse-surface: '#e2e2e2'
  inverse-on-surface: '#303030'
  outline: '#b18780'
  outline-variant: '#603e39'
  surface-tint: '#ffb4a8'
  primary: '#ffb4a8'
  on-primary: '#690100'
  primary-container: '#ff5540'
  on-primary-container: '#5c0000'
  inverse-primary: '#c00100'
  secondary: '#c8c6c5'
  on-secondary: '#313030'
  secondary-container: '#4a4949'
  on-secondary-container: '#bab8b7'
  tertiary: '#acc7ff'
  on-tertiary: '#002f67'
  tertiary-container: '#488fff'
  on-tertiary-container: '#00285b'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad4'
  primary-fixed-dim: '#ffb4a8'
  on-primary-fixed: '#410000'
  on-primary-fixed-variant: '#930100'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474646'
  tertiary-fixed: '#d7e2ff'
  tertiary-fixed-dim: '#acc7ff'
  on-tertiary-fixed: '#001a40'
  on-tertiary-fixed-variant: '#004491'
  background: '#131313'
  on-background: '#e2e2e2'
  surface-variant: '#353535'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Montserrat
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 48px
---

## Brand & Style
This design system is engineered for a high-fidelity audio experience, emphasizing an "Absolute Dark Mode" aesthetic. The brand personality is aggressive, technical, and uncompromising, designed for audiophiles and power users who prioritize focus and visual intensity.

The style is a fusion of **Minimalism** and **High-Contrast Tech**. By utilizing a void-like background, the interface eliminates peripheral distractions, allowing the content and high-energy accent colors to command total attention. Movement should feel mechanical yet fluid, mimicking high-end hardware interfaces.

## Colors
The palette is restricted to three core pillars to maintain visual discipline. 

1.  **Carbon Black (#000000):** Used exclusively for the primary canvas and background layers to achieve true-black depth on OLED screens.
2.  **Space Gray (#121212):** Used for elevated surfaces, containers, and card backgrounds to provide subtle structural definition without breaking the dark immersion.
3.  **Neon Red (#FF0000):** The singular "Action" color. This is reserved for critical paths, active states, progress indicators, and interactive borders. 

All text must maintain a high contrast ratio. Use pure white for primary information and a medium gray for metadata and secondary descriptions.

## Typography
The typography strategy pairs the geometric authority of **Montserrat** for headings with the systematic clarity of **Inter** for functional UI elements. 

- **Headlines:** Set in Montserrat with tight letter-spacing to create a "locked-in," professional tech feel.
- **Body & Metadata:** Set in Inter. Use tabular numbers for time-stamps and bitrates to ensure alignment during playback.
- **Labels:** Small labels and overlines should use uppercase with slight tracking (letter-spacing) to evoke a cockpit or technical instrument readout.

## Layout & Spacing
The design system utilizes a **Fluid Grid** based on an 8px square rhythm. 

- **Mobile:** A 4-column grid with 20px side margins. Album covers in grids should typically span 2 columns.
- **Desktop:** A 12-column grid with a fixed maximum width of 1440px for content containers.
- **Gutters:** Standardized at 16px to maintain high information density while ensuring touch targets remain accessible.

Layouts should favor verticality and list-based navigation, reflecting a library-first approach. Use generous "dead space" (Carbon Black) between major sections to prevent the high-contrast red from becoming overwhelming.

## Elevation & Depth
In an absolute dark environment, traditional drop shadows are ineffective. Depth is instead communicated through **Tonal Layering** and **Luminous Outlines**:

- **Level 0 (Floor):** Carbon Black (#000000). For the main background.
- **Level 1 (Surface):** Space Gray (#121212). For cards, drawers, and modal containers.
- **Level 2 (Active):** Neon Red Outlines. Interactive elements gain depth by glowing rather than casting shadows. 

Use 1px or 2px solid borders in Neon Red for primary buttons and active input states. Subtle 10% opacity Red overlays can be used for hover states on dark surfaces to indicate interactivity.

## Shapes
The shape language is "Technical Soft." While the brand is aggressive, pure sharp corners are avoided to keep the high-fidelity feel premium rather than dated.

- **Standard Elements:** 4px (0.25rem) radius for buttons, input fields, and small cards.
- **Containers:** 8px (0.5rem) radius for album art and large surface containers.
- **Interactive Icons:** 100% circular for play/pause toggles to distinguish them from the structural grid.

## Components
### Buttons
- **Primary:** Solid Neon Red background with Black text. 4px border radius.
- **Secondary/Outline:** Transparent background with a 2px Neon Red border and White text.
- **Ghost:** Transparent background, Red text, no border. Used for tertiary actions.

### Album Art Grid
Album covers are strictly square (1:1). In list views, use a 48px square with a 4px radius. In grid views, use a 1px Space Gray border to separate the art from the Carbon Black background if the artwork is very dark.

### Bottom Navigation
A sleek, 64px tall bar using a background of Space Gray (#121212) with a 1px Neon Red top border. Icons are white when inactive and Neon Red when active. No text labels are used if icons are universally recognizable.

### Progress Bars & Sliders
Track background is Space Gray. The "filled" portion and the "thumb" (handle) are pure Neon Red. The thumb should only appear on hover or during active scrubbing.

### Input Fields
Dark backgrounds (#121212) with a bottom-only 2px border that transitions from Gray to Neon Red on focus.