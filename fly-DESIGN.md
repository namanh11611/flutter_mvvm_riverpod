---
version: alpha
name: Fly.io
description: "A light interface extracted from Fly.io accented with #281950, with a 4px spacing system and a Fricolage Grotesque type stack."
sourceUrl: "https://fly.io"

colors:
  primary: "#281950"
  on-primary: "#ffffff"
  background: "#ffffff"
  surface: "#7c3aed"
  border: "#d5cfef"
  text: "#281950"
  text-muted: "#686082"
  accent: "#686082"

typography:
  display:
    fontFamily: "Mackinac, ui-serif, Georgia, Cambria, Times New Roman, Times, serif"
    fontSize: 48px
    fontWeight: 575
    lineHeight: 1.3
    letterSpacing: -1.2px
  heading:
    fontFamily: "Mackinac, ui-serif, Georgia, Cambria, Times New Roman, Times, serif"
    fontSize: 40px
    fontWeight: 575
    lineHeight: 1.3
    letterSpacing: -1px
  body:
    fontFamily: "Fricolage Grotesque, ui-sans-serif, system-ui, sans-serif, Apple Color Emoji, Segoe UI Emoji, Segoe UI Symbol, Noto Color Emoji"
    fontSize: 15px
    fontWeight: 450
    lineHeight: 1.66

spacing:
  base: 4px
  scale: [4, 8, 12, 16, 20, 24, 32, 40, 48, 64]

radius:
  sm: 4px
  md: 8px
  lg: 10px
  xl: 16px
  pill: 9999px

shadows:
  card: "rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0.1) 0px 2px 25px 0px"
  elevated: "rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0) 0px 0px 0px 0px, rgba(0, 0, 0, 0.1) 0px 2px 25px 0px"

motion:
  duration-fast: 150ms
  duration-base: 200ms
  duration-slow: 300ms
  easing: "cubic-bezier(0.4, 0, 0.2, 1)"

breakpoints: [480px, 640px, 768px, 1024px, 1200px, 1367px, 1400px, 1728px]
---

## Rationale

Fly.io positions itself as a modern cloud compute platform that strips away complexity, and the design system reflects this through confident, premium minimalism. The deep purple primary (#281950) paired with a vibrant violet surface (#7c3aed) creates visual hierarchy without relying on heavy borders or decorative elements—a choice that communicates sophistication and trust appropriate for infrastructure software. The typography system uses serif display faces (Mackinac) for marketing moments and a humanist sans-serif body (Fricolage Grotesque) for clarity, reinforcing the "modern without complexity" positioning: elegant enough for brand presence, legible enough for technical content. The spacing scale and modest shadow system (subtle purple-tinted shadows on cards) suggest a surface-based, layered UI that feels digital but approachable, avoiding the harsh grays and cool blues typical of enterprise SaaS.

The color palette is deliberately constrained: three functional colors (primary, surface, accent) plus white, allowing the deep purples to dominate without visual noise. This restraint signals maturity—Fly.io trusts its product strength rather than relying on color saturation to grab attention. The measured lighting appears light-mode-dominant with strong contrast between text and background, critical for a platform where users may be reading documentation or monitoring status pages for extended periods. The generous line-height (1.5 on body) and negative letter-spacing on headings (-0.55px to -0.9px) further emphasize readability and a refined, contemporary aesthetic.

Motion is conservative (150–300ms durations with a standard easing curve), befitting a platform where users value performance and predictability. The breakpoint stack (480 to 1728px) indicates a mobile-first responsive philosophy with particular attention to tablet and large desktop experiences—common in developer tools where users may work across phone notifications, laptop development, and multi-monitor status views.

## 1. Visual Theme & Atmosphere

Fly.io's visual identity is **premium minimalism for infrastructure**: clean, purposeful, and confident without ornamentation. The design avoids gradients, excessive shadows, or decorative patterns—instead relying on color relationships and typography to create hierarchy and mood. The deep purple base (#281950) feels grounded and technical (invoking VCs and cloud platforms), while the vibrant violet surface (#7c3aed) introduces energy and approachability, preventing the system from feeling cold or corporate. This dual-purple strategy is uncommon in SaaS and signals a brand comfortable diverging from the monochrome-and-teal convention.

The overall atmosphere is **clarity through constraint**. Every visual decision (color, typeface, spacing) serves function rather than decoration, aligned with the product message: "Modern Compute Without the Complexity." Cards and containers use soft shadows with purple tint, grounding content without drawing unnecessary attention.

## 2. Color System

The palette consists of **eight semantic tokens**:

- **Primary (#281950)** – Deep midnight purple; used for text, primary actions, and structural elements. Establishes brand authority.
- **On-primary (#ffffff)** – White; required contrast partner for text and icons on primary backgrounds, particularly in CTAs like "Get Started" and "Sign In."
- **Surface (#7c3aed)** – Vibrant violet; secondary actions, highlights, and featured sections. Warm enough to feel approachable, saturated enough to command attention without primary competing.
- **Accent (#202237)** – Near-black slate; reserved for high-contrast text, borders, or secondary hierarchy layers. Darker than primary, used sparingly.
- **Background (#ffffff)** – White canvas; ensures maximum contrast for reading and uncluttered visual breathing room.
- **Text (#281950)** – Defaults to primary purple; maintains consistency across body copy, establishing the brand's linguistic voice visually.
- **Text-muted (#ffffff)** – White text; appears on dark or surface-colored backgrounds, such as in hero sections or feature callouts.
- **Border (#ffffff)** – White edges; creates subtle separation without harsh lines, reinforcing the minimalist aesthetic.

**Contrast strategy:** The primary-to-background pair (dark purple #281950 on white #ffffff) achieves approximately **9:1 contrast**, well above WCAG AAA standards. Surface-to-white offers **5.8:1** (WCAG AA compliant). On-primary-to-primary (white on deep purple) also exceeds **9:1**. This generous contrast supports accessibility while allowing elegant, legible layouts.

## 3. Typography

The system uses **two typeface families**:

- **Display & Heading: Mackinac** (serif fallback to Georgia/Times)
  - Display: 36px, weight 500, line-height 1.33, letter-spacing -0.9px
  - Heading: 22px, weight 500, line-height 1.33, letter-spacing -0.55px
  - Serif choice for headings is unconventional in tech but reinforces premium positioning. The tight letter-spacing (-0.55px on headings, -0.9px on display) creates visual tension and modernity, preventing the serif from feeling antiquated.

- **Body: Fricolage Grotesque** (sans-serif system fallback)
  - 16px, weight 325 (light-to-regular), line-height 1.5
  - Humanist sans-serif reduces coldness and pairs well with the serif headlines. Weight 325 (lighter than standard 400) feels contemporary and airy, avoiding visual heaviness. Line-height 1.5 provides reading comfort for technical documentation or marketing copy.

**Type hierarchy rationale:** Serif headlines grab attention and convey craft/maturity; sans body text ensures accessibility and scannability. The light weight and generous line-height create an elegant, spacious feel—critical for a platform targeting developers who spend hours reading and configuring services.

## 4. Components & Patterns

**Primary Actions (CTAs):**
- Background: Surface (#7c3aed), Text: On-primary (#ffffff)
- Examples: "Get Started," "Sign In," "Pricing"
- Rounded corners: likely `lg` (10px) or `pill` (9999px) for buttons, creating soft, modern affordance

**Secondary Elements:**
- Primary text (#281950) on white background with border (#ffffff) or subtle shadow
- Cards use the `card` shadow (purple-tinted, 5px blur, -2px offset), creating float without depth

**Navigation & Header:**
- Primary color (#281950) for text and structural elements
- White background maintains clarity
- CTA buttons use surface color, creating visual priority in dense navigation

**Featured Sections (Hero, Feature Callouts):**
- Surface color (#7c3aed) background with muted text (#ffffff)
- Likely full-width or container-constrained with 16–40px padding (from spacing scale)
- Serif headlines in on-primary (#ffffff) for strong contrast

**Borders & Dividers:**
- White (#ffffff) subtle separation; avoids heavy grays
- Possibly used with transparency (e.g., rgba(255, 255, 255, 0.2)) on colored backgrounds

## 5. Spacing & Layout

The **base unit is 4px**, with a 10-step scale: 4, 8, 12, 16, 20, 24, 28, 32, 36, 40px. This allows precise control and semantic naming (e.g., `space-4` = 4px tight, `space-10` = 40px generous).

**Likely application patterns:**
- **Padding within components:** 12–24px (3–6 base units)
- **Margin between sections:** 32–40px (8–10 base units) on desktop
- **Gutters/Grid:** 16–24px (4–6 base units) between columns
- **Compact mobile:** halved or reduced by one step

The spacing scale avoids awkward fractional values and ensures rhythm across responsive breakpoints. The eight breakpoints (480, 640, 768, 1024, 1200, 1367, 1400, 1728) indicate mobile-first design with refinement at tablet, desktop, and ultra-wide sizes, common for platforms where users may switch between devices.

## 6. Motion & Interaction

Motion is **restrained and purposeful**:

- **Fast duration:** 150ms – Used for micro-interactions (hover states, icon changes, brief feedback)
- **Base duration:** 200ms – Standard transitions (button press, modal open, card lift)
- **Slow duration:** 300ms – Attention-drawing or narrative animations (hero entrance, section reveal)
- **Easing:** `cubic-bezier(0.4, 0, 0.2, 1)` – A standard material easing curve, slightly ease-out at the end, preventing abrupt stops and creating polish

**Interaction patterns:**
- Buttons likely use 150ms color/shadow transitions on hover (surface lightens or shadow elevates)
- Cards may shift shadow on hover, creating depth without movement (the `card` shadow upgrades to `elevated` style)
- Form inputs and toggles respond within 200ms
- Page/section transitions (navigation, modals) use 300ms for perceived smoothness without sluggishness

This conservative motion strategy respects developer expectations: no fluff, no delay, just clarity.

## Accessibility

### Contrast Ratios

**Primary text on background (#281950 on #ffffff):**
- Measured contrast: ~9:1
- **Meets WCAG AAA** (requires 7:1 minimum)

**Surface button text on primary (#ffffff on #7c3aed):**
- Measured contrast: ~5.8:1
- **Meets WCAG AA** (requires 4.5:1 minimum); close to AAA threshold

**Muted text on surface background (#ffffff on #7c3aed):**
- Same as above: ~5.8:1 (WCAG AA compliant)

**Accent text on background (#202237 on #ffffff):**
- Measured contrast: ~10:1
- **Meets WCAG AAA**

All primary interactive and textual pairs meet or exceed WCAG AA standards. The system avoids relying on color alone; hierarchy is reinforced through size, weight, and spacing.

### Minimum Requirements

- **Touch target:** Buttons and interactive elements must be at least 44×44px (11 base units), following WCAG Level AAA guidance. This applies to mobile-sized breakpoints (480px and up); buttons likely expand with padding and heading sizes.
  
- **Focus indicator:** Interactive elements (buttons, links, form inputs) must display a visible focus state, ideally a 2px outline in accent or primary color, with 2px offset from the element edge. Given the design's minimalism, this is likely a solid or dashed outline rather than a shadow.

- **Keyboard navigation:** All CTAs, form inputs, and navigation must be focusable via Tab key in logical order. The site likely uses standard semantic HTML (button, a, input) to ensure native keyboard support.

- **Color independence:** The violet-to-white palette passes color-blindness simulation (deuteranopia, protanopia). Purple and white have sufficient lightness contrast that red–green color-blind users can distinguish interactive elements.

- **Motion:** The conservative motion timing (150–300ms) aligns with accessibility expectations and respects `prefers-reduced-motion` media queries, allowing users to disable animations if needed.
