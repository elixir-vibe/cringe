# Changelog

## Unreleased

- Replace the `Cringe.Test` helper module with `Cringe.Assertions`, `Cringe.Case`, and `Cringe.Driver`.
- Preserve active ANSI SGR styling in `Cringe.Measure.take/2`.
- Let `Cringe.Painter` manage terminal cursor visibility from frame cursor state.
- Extract layout-node drawing into `Cringe.Renderer.Draw`.
- Add document IDs, layout node lookup, and coordinate hit testing.
- Add runtime tick events with configured intervals.
- Add ticking spinner example.
- Move ANSI text styling into the draw phase for styled text overlays.
- Add app driver helpers for key sequences and deterministic awaits.
- Add focusable layout metadata and coordinate path lookup.
- Add draw-owned box border and content-rect primitives.

## 0.2.0 (2026-05-26)

Interactive alpha release.

- Add Ghostty-backed terminal input and terminal backend integration.
- Add semantic runtime events for keys, text, resize, and ticks.
- Add focus ring helpers.
- Add render-only widgets: input, select, progress, and spinner.
- Add cursor-aware input state and input update helpers.
- Add painter-backed runtime repainting and cursor movement output.
- Add canvas-backed frame rendering.
- Add basic box overflow clipping and vertical scrolling.
- Add terminal-cell-aware measurement for emoji, CJK, combining marks, and ANSI-styled text.
- Add benchmark harness for render, canvas, painter, and input paths.
- Add interactive examples for counters, input, and forms.

## 0.1.0 (2026-05-25)

Initial alpha release.

- Add document DSL for text, rows, columns, and boxes.
- Add ANSI styling support.
- Add frame renderer, painter, supervised runtime skeleton, and ExUnit helpers.
- Add basic examples and documentation.
