---
name: Translational Surface
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1b1b1c'
  surface-container: '#202020'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353535'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c3c6d1'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#303030'
  outline: '#8d919b'
  outline-variant: '#424750'
  surface-tint: '#a8c8ff'
  primary: '#b5cfff'
  on-primary: '#003061'
  primary-container: '#8ab4f8'
  on-primary-container: '#0d4582'
  inverse-primary: '#315f9d'
  secondary: '#a7cbe3'
  on-secondary: '#0a3447'
  secondary-container: '#294d61'
  on-secondary-container: '#99bdd4'
  tertiary: '#b3cfff'
  on-tertiary: '#0a315b'
  tertiary-container: '#95b4e6'
  on-tertiary-container: '#254671'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a8c8ff'
  on-primary-fixed: '#001b3c'
  on-primary-fixed-variant: '#114784'
  secondary-fixed: '#c3e7ff'
  secondary-fixed-dim: '#a7cbe3'
  on-secondary-fixed: '#001e2c'
  on-secondary-fixed-variant: '#264b5e'
  tertiary-fixed: '#d5e3ff'
  tertiary-fixed-dim: '#a9c8fb'
  on-tertiary-fixed: '#001c3b'
  on-tertiary-fixed-variant: '#274773'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353535'
typography:
  display-lg:
    fontFamily: Roboto Flex
    fontSize: 44px
    fontWeight: '400'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Roboto Flex
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
    letterSpacing: 0em
  headline-lg-mobile:
    fontFamily: Roboto Flex
    fontSize: 26px
    fontWeight: '500'
    lineHeight: 32px
    letterSpacing: 0em
  headline-md:
    fontFamily: Roboto Flex
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 32px
    letterSpacing: 0em
  headline-sm:
    fontFamily: Roboto Flex
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
    letterSpacing: 0em
  title-lg:
    fontFamily: Roboto Flex
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0.01em
  title-md:
    fontFamily: Roboto Flex
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 22px
    letterSpacing: 0.01em
  body-lg:
    fontFamily: Roboto Flex
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.02em
  body-sm:
    fontFamily: Roboto Flex
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.03em
  label-lg:
    fontFamily: Roboto Flex
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Roboto Flex
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Roboto Flex
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-lg: 1.5rem
  margin: 1rem
  margin-md: 1.5rem
  margin-lg: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

This design system draws direct inspiration from modern Material Design 3 and Google's dark surface paradigm. The experience is engineered to be calm, highly utilitarian, and instantly legible, reducing visual fatigue during deep cognitive focus.

- **Aesthetic Movement:** Modern Material Surface / Adaptive Functionalism. 
- **Emotional Intent:** Restful precision, optical clarity, unobtrusive reliability, and ambient warmth without artificial neon illumination.
- **Visual Discipline:** Surface hierarchy relies on calibrated tonal stepping and subtle luminance shifts rather than heavy drop shadows, harsh borders, or vibrant glow effects. Visual interest is derived from generous spatial paddings, distinct tonal nesting, and intentional focal accents using calibrated soft blues.

## Colors

The palette embraces the subtle, layered depths of Google's dark theme philosophy. Pure black (#000000) is avoided for backgrounds to prevent extreme contrast eye-strain and halation around text.

### Surface Tones & Roles
- **Background Canvas (`#131314`):** The ground level for high-density reading and full-canvas views.
- **Surface Default (`#1F1F1F`):** Standard page canvas and baseline container base.
- **Surface Container Low (`#1E1F20`):** Recessed functional wells, inactive input regions, or canvas framing.
- **Surface Container (`#282A2C`):** Primary card modules, source/target translation panels, and dialogue frames.
- **Surface Container High (`#313335`):** Overlays, popovers, dropdown lists, and hovered surfaces.
- **Surface Container Highest (`#3B3D40`):** Micro-surfaces, tooltips, and active chip states.

### Accent & Text Roles
- **Primary Interactive Accent (`#8AB4F8`):** Desaturated Google Blue tailored for dark luminance. Used for active tabs, selected states, floating action triggers, and active glyphs.
- **Secondary Accent (`#C2E7FF`):** Tonal fill container accent for active state highlights, pill chip selections, and high-emphasis indicator badges.
- **Text Primary (`#E8EAED`):** 87% effective luminance white for primary editorial titles, translated strings, and primary iconography.
- **Text Secondary (`#9AA0A6`):** 60% neutral gray for metadata, phonetic notations, counter tags, labels, and helper copy.
- **Outlines & Dividers (`#3C4043` / `#444746`):** Minimal hairpins for structural segmentation. Default borders remain at `#444746` with 1px width, softening to `#3C4043` for low-priority panel dividers.

## Typography

The type system relies on **Roboto Flex** to deliver clear, mechanical yet humanist legibility across multilingual viewports.

- **Hierarchy Structure:** Large titles maintain generous line heights to accommodate non-Latin diacritics, scripts, and phonetic transcriptions without clipping.
- **Weights & Spacing:** Headlines utilize regular weights (`400`) to prevent heavy dark-mode optical spread (irradiation phenomenon). Labels and buttons leverage medium weights (`500`) with positive letter-spacing (`0.01em` to `0.05em`) for quick scanning.
- **Reading Comfort:** Long-form translated text adheres to `body-lg` (18px) or `body-md` (14px) with a line-height multiplier between `1.42` and `1.45`, ensuring natural reading cadence.

## Layout & Spacing

The layout is built on an adaptive responsive grid adhering to an 8-point base increment (with 4-point micro-adjustments for tight utility bars and icon positioning).

### Grid Strategy
- **Desktop (>= 1200px):** 12-column layout with 24px gutters and 32px canvas margins. Dual-pane source/target cards sit side-by-side with 1:1 width proportions across 6 columns each.
- **Tablet (600px - 1199px):** 8-column layout with 16px gutters and 24px margins. Content cards adjust either side-by-side or stack vertically depending on pane expansion.
- **Mobile (< 600px):** 4-column layout with 16px margins and 16px gutters. Dual-pane cards transition into an accordion or stacked vertical arrangement, prioritizing the input workspace with fixed tool anchors at the base.

## Elevation & Depth

In alignment with Material 3 Dark specifications, elevation is defined via **tonal stepping** and surface luminance rather than dramatic drop shadows.

- **Level 0 (Flat/Base):** `#131314` or `#1F1F1F`. No shadow. Baseline canvas.
- **Level 1 (Card Modules & Base Inputs):** `#282A2C`. Outlined with a 1px border of `#444746`. Shadows are purely ambient: `0 1px 3px rgba(0, 0, 0, 0.2)`.
- **Level 2 (Hovered Cards & Segmented Toolbars):** `#2D2F31`. Tonal increase. Ambient shadow: `0 2px 6px rgba(0, 0, 0, 0.25)`.
- **Level 3 (Floating Menus & Dropdown Lists):** `#313335`. Ambient shadow: `0 4px 12px rgba(0, 0, 0, 0.35)`.
- **Level 4 (Modals & Command Dialogs):** `#3B3D40`. Elevated modal surfaces, bordered by 1px `#444746`, backdropped by a 60% black scrim (`rgba(0, 0, 0, 0.6)`).
- **Rule on Glows:** No colored ambient drop-shadows or saturated neon blurs. Accent blue (`#8AB4F8`) is strictly applied to fills and icon strokes, never to drop shadows.

## Shapes

The shape architecture relies on friendly, organic pill geometries contrasting against structural, generously rounded content surfaces.

- **Pill Geometry (Full Radius / 9999px):** Applied to interactive utility controls, language selection switches, filter chips, action pills, and search bars.
- **Large Surface Containers (`24px` to `28px` / `rounded-xl`):** Dedicated translation cards, floating panels, bottom sheets, and dialogs.
- **Micro Radii (`8px` to `12px`):** Context menus, tooltips, and copy feedback snackbars.

## Components

### Buttons & Language Switchers
- **Filled Primary Button:** Full pill height (`40px`), fill `#8AB4F8`, text color `#041E49` (high contrast dark navy), font `label-lg`. Hover: brightness increased to `#A8C7FA`.
- **Tonal Secondary Button:** Full pill height (`40px`), fill `#004A77` (deep desaturated blue) with text `#C2E7FF`.
- **Language Selector Bar:** Symmetrical pill-shaped tab container (`#282A2C` background, 1px `#444746` border). Language tabs inside are pill-shaped (`32px` height) with `#8AB4F8` active text on `#004A77` or `#3B3D40` container state. Inactive text is `#9AA0A6`. Center swap icon button uses a 36px circular target with active rotation feedback.

### Translation Cards & Input Panes
- **Structure:** Framed inside `#282A2C` with subtle 1px `#444746` boundaries. Radius is `24px`.
- **Input Text Field:** Borderless background within the card canvas. Text color `#E8EAED` at `body-lg` or `headline-sm`. Character count, clear button, and mic triggers sit pinned at the card footer.
- **Output Target Field:** Matched container with subtle contrast or nested well (`#1F1F1F`), providing instant visual distinction from editable space. Action icons (Copy, Sound/Speaker, Share, Star) align horizontally along the card's bottom edge using desaturated `#9AA0A6` hover-tinted to `#E8EAED`.

### Filter & History Chips
- **Resting:** `32px` pill height, background transparent, 1px border `#444746`, text `#9AA0A6`, icon size 18px.
- **Selected:** Background `#004A77`, border `#8AB4F8`, text `#C2E7FF`.
- **Hover:** Background `#313335` with text transitioning to `#E8EAED`.

### Lists & History History Entries
- **Dividers:** Minimal 1px hairline dividers using `#3C4043` with 16px start/end indents.
- **List Item:** 56px minimum touch height, background transparent, transitioning to `#313335` on interaction. Primary string `#E8EAED`, translated secondary string `#9AA0A6`.

### Inputs, Checkboxes & Radio Controls
- **Form Inputs:** Filled style, base `#1E1F20`, indicator border `#444746`. Focus state transitions bottom indicator to `#8AB4F8` (2px).
- **Checkboxes & Radios:** Selected fill `#8AB4F8` with dark glyph `#041E49`. Unselected outline `#9AA0A6` (2px).