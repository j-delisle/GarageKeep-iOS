# Design System Documentation: The Precision Atelier

This design system is a high-end, editorial-inspired framework crafted for deep-mode environments. It moves away from the "standard app" aesthetic by prioritizing tonal depth, intentional asymmetry, and a "Precision Atelier" philosophy—blending the rugged utility of a high-end garage with the sleek, technical elegance of modern automotive design.

## 1. Overview & Creative North Star
**Creative North Star: The Precision Atelier**
The system is built on the concept of "Technical Luxury." It rejects the generic "card-on-grey" layout in favor of a layered, immersive experience. We use **Plus Jakarta Sans** for high-impact editorial moments and **Manrope** for data-heavy utility. The interface should feel like a custom-tuned engine: every element is necessary, every transition is frictionless, and the aesthetic is unapologetically premium.

### Editorial Signature
*   **Intentional Asymmetry:** Break the grid by staggering card heights or using off-center typography in hero sections to create a "magazine" feel.
*   **Negative Space as a Feature:** Whitespace (or "Darkspace") is not "empty"—it is a structural element used to isolate high-value vehicle data.

---

## 2. Colors
The palette is rooted in a deep, sophisticated dark scale, punctuated by a vibrant, high-energy teal.

### The Palette
*   **Primary (`#59d9d9`):** Our "Teal Ignition" color. Use it sparingly for critical actions and state indicators.
*   **Surface Hierarchy:** We utilize the `surface-container` tokens to create a sense of physical architecture. 
    *   `surface` (#131315) is the base floor.
    *   `surface-container-low` (#1b1b1d) defines secondary zones.
    *   `surface-container-highest` (#353437) creates prominence for active modals or prioritized data.

### The Rules of Engagement
*   **The "No-Line" Rule:** 1px solid borders for sectioning are strictly prohibited. Define boundaries through background color shifts. For example, a `surface-container-low` card sits on a `surface` background to define its shape.
*   **The "Glass & Gradient" Rule:** To elevate beyond flat UI, use Glassmorphism for floating headers or navigation bars. Apply a `backdrop-blur` with a semi-transparent `surface-container` color.
*   **Signature Textures:** For primary CTAs, use a subtle linear gradient from `primary` (#59d9d9) to `primary-container` (#00a8a8) at a 135-degree angle. This adds "soul" and depth that a flat fill cannot achieve.

---

## 3. Typography
Typography is our primary tool for hierarchy. We pair the geometric authority of Plus Jakarta Sans with the functional clarity of Manrope.

| Level | Token | Font | Size | Intent |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Plus Jakarta Sans | 3.5rem | High-impact vehicle stats (e.g., Odometer). |
| **Headline** | `headline-md` | Plus Jakarta Sans | 1.75rem | Page titles and major section headers. |
| **Title** | `title-md` | Manrope | 1.125rem | Card headers and sub-navigation. |
| **Body** | `body-md` | Manrope | 0.875rem | General information and descriptions. |
| **Label** | `label-sm` | Manrope | 0.6875rem | Technical specs and metadata labels. |

---

## 4. Elevation & Depth
Depth in this system is achieved through **Tonal Layering** rather than traditional drop shadows.

*   **The Layering Principle:** Stack surfaces to create "lift." A `surface-container-lowest` element placed within a `surface-container-high` zone creates a "carved out" effect, perfect for input fields.
*   **Ambient Shadows:** When an element must "float" (like a FAB or a floating menu), use a shadow with a 24pt-32pt blur at 6% opacity. Use the `on-surface` color for the shadow tint to keep it natural.
*   **The "Ghost Border" Fallback:** If a container requires extra definition (e.g., in high-density data views), use the `outline-variant` token at **15% opacity**. This creates a "whisper" of a line that guides the eye without cluttering the UI.
*   **Glassmorphism:** Use `surface-container-low` at 70% opacity with a 20px background blur for components that overlay content.

---

## 5. Components

### Buttons
*   **Primary:** Gradient fill (`primary` to `primary-container`), `xl` (1.5rem) roundedness. Typography: `title-sm` (Manrope).
*   **Secondary:** Ghost style. No fill, `outline-variant` ghost border (20% opacity). Typography: `primary` color.
*   **Tertiary:** No border, no fill. Used for "Cancel" or "Back" actions.

### Cards & Lists
*   **The Forbid Rule:** Divider lines between list items are forbidden. 
*   **Separation:** Use `spacing.4` (1rem) of vertical white space or a subtle shift from `surface-container-low` to `surface-container-lowest`.
*   **Rounding:** All cards must use `xl` (1.5rem) corner radius for a modern iOS feel.

### Input Fields
*   **State:** Default state uses `surface-container-highest` background.
*   **Focus:** Transition the background to `surface-bright` and add a `primary` ghost border (20% opacity). No heavy strokes.

### Chips (Vehicle Tags/Status)
*   **Style:** Use `surface-container-high` with `full` (9999px) rounding.
*   **Active:** Background shifts to `primary`, text shifts to `on-primary`.

---

## 6. Do's and Don'ts

### Do
*   **Do** use `display-lg` for single, "hero" numbers (like 12,450 miles).
*   **Do** leverage the `tertiary` color (#ffb691) for warning states or "Service Overdue" alerts to contrast against the teal.
*   **Do** use SF Symbols with a "Medium" or "Semibold" weight to match the `title-md` typography.

### Don't
*   **Don't** use pure black (#000000). Always use `surface` (#131315) to maintain tonal depth.
*   **Don't** use the `primary` color for large background areas. It is a "laser" meant for accents, not a "paint bucket."
*   **Don't** use standard 1px dividers. If you feel the need for a line, use a `surface-container` color shift instead.
*   **Don't** crowd the edges. Respect the `spacing.6` (1.5rem) outer margin for all mobile screens.