# Production UI reference

The production Flutter UI must preserve the visual language and hierarchy of
**Variant A — Scan home** from branch `prototype/scan-first-experience`, commit
`c2fec925e05f451dd5e729a07eeb6058a3e84e4d`. The prototype is the normative
reference for how the product should look and feel, not only for its navigation
model.

## Visual language

- Use the prototype's warm off-white canvas and surfaces, near-black ink,
  muted gray-green supporting text, deep green primary actions, and lime accent.
- Keep the compact brand header with the `F` mark, `FilaManager`, the
  `Scan-led context` descriptor, and a visible local-only status pill.
- Make the Scan home hero the strongest visual element: a large rounded
  dark-green surface, a framed scan glyph, a direct action label, and concise
  placement guidance.
- Use strongly rounded cards, controls, sheets, and navigation surfaces with
  restrained borders and soft shadows.
- Keep Home, Spools, Places, and Archive in a rounded persistent navigation
  surface. Preserve the same hierarchy when adapting to wider layouts.
- Use uppercase eyebrow labels, bold tightly spaced headings, concise muted
  supporting copy, and generous vertical spacing.
- Present guided operations in rounded bottom sheets that collect inputs,
  show a complete review, and reserve the strongest button for final
  confirmation.
- Keep status pills, warnings, success messages, occupancy cards, spool color
  swatches, and non-color cues visually consistent with the prototype.

## Control hierarchy and responsive layout

- Give each screen one clear primary action. Use the same visual treatment for
  choices with the same priority; use outlined or text controls for genuinely
  secondary actions. Do not make one of two equivalent choices look like the
  default decision.
- When one action branches into several object types, show one entry action and
  then a choice sheet with equally styled options. Continue into the existing
  guided form only after the hobbyist chooses a type.
- Build repeated controls from shared Flutter components and theme values so
  color, typography, corner radius, padding, icon placement, and interaction
  states remain consistent across screens.
- At compact phone widths, keep the primary action stable and readable. Use a
  choice sheet or menu when sibling actions would wrap into an accidental
  vertical stack. Check changed action layouts at 320–420 logical pixels,
  larger text scale, and at least 600 logical pixels; inspect the target device
  when a layout problem was reported there.

## Production boundaries

Reproduce the design in production Flutter components; do not copy the
prototype's HTML/JavaScript architecture. Do not ship the prototype flag,
variant switcher, Scenario lab, state inspector, seeded test inventory, or
emoji-only controls. Production terminology, accessibility semantics, adaptive
layout, and platform behavior override literal prototype text where necessary.

When a ticket introduces a screen or state not shown in Variant A, extend this
visual system rather than introducing a separate style.
