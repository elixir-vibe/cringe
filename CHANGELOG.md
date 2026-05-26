# Changelog

## Unreleased

- Replace the `Cringe.Test` helper module with `Cringe.Assertions`, `Cringe.Case`, and `Cringe.Driver`.

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
