---
name: Aureate Technical
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
  on-surface-variant: '#d5c4b3'
  inverse-surface: '#e2e2e2'
  inverse-on-surface: '#303030'
  outline: '#9d8e7f'
  outline-variant: '#504538'
  surface-tint: '#f9bb6e'
  primary: '#f9bb6e'
  on-primary: '#472a00'
  primary-container: '#bd863e'
  on-primary-container: '#3e2400'
  inverse-primary: '#83540f'
  secondary: '#c7c6cb'
  on-secondary: '#2f3034'
  secondary-container: '#46464b'
  on-secondary-container: '#b5b4ba'
  tertiary: '#d0bcff'
  on-tertiary: '#3c0091'
  tertiary-container: '#a078ff'
  on-tertiary-container: '#340080'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffddb8'
  primary-fixed-dim: '#f9bb6e'
  on-primary-fixed: '#2a1700'
  on-primary-fixed-variant: '#653e00'
  secondary-fixed: '#e3e2e7'
  secondary-fixed-dim: '#c7c6cb'
  on-secondary-fixed: '#1a1b1f'
  on-secondary-fixed-variant: '#46464b'
  tertiary-fixed: '#e9ddff'
  tertiary-fixed-dim: '#d0bcff'
  on-tertiary-fixed: '#23005c'
  on-tertiary-fixed-variant: '#5516be'
  background: '#131313'
  on-background: '#e2e2e2'
  surface-variant: '#353535'
  surface-low: '#111214'
  surface-medium: '#1B1C20'
  surface-high: '#282A2F'
  brass-muted: '#6E4C1F'
  glass-stroke: rgba(255, 255, 255, 0.08)
typography:
  display-lg:
    fontFamily: literata
    fontSize: 48px
    fontWeight: '600'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: literata
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
  headline-md:
    fontFamily: literata
    fontSize: 24px
    fontWeight: '500'
    lineHeight: '1.3'
  body-lg:
    fontFamily: inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: -0.01em
  body-md:
    fontFamily: inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: jetbrainsMono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.0'
    letterSpacing: 0.05em
  technical:
    fontFamily: jetbrainsMono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: '1.4'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 24px
  margin-desktop: 64px
  margin-mobile: 20px
  container-max: 1440px
---

## Brand & Style

The design system is a high-performance, enterprise-grade aesthetic designed for "Placement Connect." It targets executive-level users and technical power users who demand both aesthetic prestige and functional density. 

The style is **Luxury Minimalist SaaS**. It merges the austere precision of high-end developer tools with the material richness of luxury branding. By combining deep monochromatic surfaces with metallic brass accents, the system evokes a sense of "digital craftsmanship." Visual interest is generated through light rather than color—using subtle glassmorphism, hairline borders, and atmospheric glows to define space. The emotional response is one of absolute reliability, exclusivity, and focused productivity.

## Colors

The palette is anchored in a "True Dark" philosophy. The primary background is a pure black (#000000), which allows the brass/gold primary color (#A9752F) to achieve maximum luminosity without overwhelming the user. 

- **Primary (Brass):** Used sparingly for critical CTAs, active states, and brand-defining moments.
- **Surface Tiers:** Depth is created through a hierarchy of dark grays. `#111214` acts as the base container, while `#1B1C20` and `#282A2F` represent elevated surfaces like cards and modals.
- **Accents:** A tertiary violet (#8B5CF6) is reserved for technical success states or specialized "pro" features, providing a cool-toned counterpoint to the warm brass.
- **Glassmorphism:** Overlays use semi-transparent variations of the surface colors with a background blur (minimum 12px) to maintain legibility.

## Typography

This design system employs a high-contrast typographic pairing to balance heritage with technology. 

- **Display & Headlines:** Literata (serving as the elegant serif alternative) is used for marketing headers and dashboard titles. It should be typeset with tight letter-spacing to emphasize its editorial quality.
- **Body & UI:** Inter provides a neutral, highly legible foundation for data-heavy views and application logic.
- **Labels & Mono:** JetBrains Mono is used for metadata, status labels, and technical values, reinforcing the "Technical SaaS" identity.

All serif headlines should utilize optical sizing where possible to maintain stroke integrity at large scales.

## Layout & Spacing

The layout philosophy follows a **Rigid Fluidity** model. While the content scales to fill width, it is constrained by generous side margins to maintain a premium "gallery" feel.

- **Grid:** A 12-column grid is used for desktop, shifting to 1 column for mobile. 
- **Rhythm:** An 8px linear scale (with 4px sub-steps) governs all padding and margins. 
- **Whitespace:** Emphasize "macro-white-space" (space between sections) to prevent the dark UI from feeling claustrophobic. Components should have internal breathing room that is 1.5x larger than standard SaaS benchmarks to communicate luxury.

## Elevation & Depth

Depth is achieved through **Luminous Layering** rather than traditional heavy shadows.

- **Tonal Elevation:** Higher elevation levels are represented by lighter surface colors. 
- **Atmospheric Shadows:** Shadows are large, soft, and include a subtle tint of the primary color (e.g., `rgba(169, 117, 47, 0.05)`) to make elevated elements feel as though they are casting a faint metallic glow.
- **Hairline Borders:** Every elevated element (cards, menus) must have a 1px solid border using `glass-stroke`. On the top edge, use a slightly brighter 1px "inner highlight" to simulate light catching the edge of a physical material.
- **Backdrop Blur:** Modals and navigation bars use a 20px blur with a 70% opacity fill of `surface-low`.

## Shapes

The design system utilizes a **Sophisticated Softness**. 

Corners are kept relatively tight (4px for small components, 8px for cards) to maintain a professional, architectural feel. Fully rounded "pill" shapes are strictly reserved for status indicators (chips) and search bars. Interactive elements should never be sharp (0px), as the goal is to feel premium and approachable, not aggressive.

## Components

- **Buttons:** Primary buttons use a solid Brass gradient background with dark text. Secondary buttons use a "ghost" style with a hairline border that brightens on hover. Use a 200ms ease-out transition for all hover states.
- **Cards:** Cards are the cornerstone of the system. They feature a `surface-medium` background, a 1px `glass-stroke`, and a very subtle 24px-spread shadow. For "Featured" cards, a top-border of 2px Brass is permitted.
- **Input Fields:** Inputs are monochromatic with a pure black background. The focus state should transition the border color to Brass and add a 2px outer glow.
- **Status Chips:** Use JetBrains Mono for text. Chips should be low-contrast (background only 10% opacity of the status color) to avoid distracting from the typography.
- **Technical Iconography:** Use thin-stroke (1.5pt) linear icons. Icons should be dual-toned, where a secondary path in the icon uses a lower opacity.
- **Navigation:** The side navigation is docked to the left with a `surface-low` background and no border, using only whitespace to separate it from the main content stage.