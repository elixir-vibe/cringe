# Changelog

## Unreleased

- Disable terminal autowrap while the terminal backend owns the screen to avoid full-width repaint drift.
- Add interactive and static terminal showcase examples covering current widgets and overlays.
- Add runtime-owned overlay state with show, hide, clear, and repaint APIs.
- Add a generic `Cringe.Widgets.Menu` with sections, separators, shortcuts, and disabled items.
- Add pure document-level overlay composition with positioned layers.
- Document shared widget state, render, keymap, and update-result conventions.
- Add a generic `Cringe.Widgets.Tabs` with struct-backed tabs and selection state.
- Render width- and height-limited editors around the current cursor position.
- Add a generic `Cringe.Widgets.Table` with struct-backed columns, rows, and selection state.
- Add a generic `Cringe.Widgets.Dialog` with struct-backed actions and selection state.
- Add a generic `Cringe.Widgets.Form` container with struct-backed fields and focus state.
- Add a render-only multiline `Cringe.Widgets.Editor` with explicit editing state.
- Add `Cringe.Keymap` with struct-backed bindings for semantic widget shortcuts.
- Add a scrollable `Cringe.Widgets.SelectList` with struct-backed items and state.
- Document layout query and focus helpers as public API.
- Add explicit text lines to layout nodes.
- Add a layout-derived focus form example.
- Clarify that `Cringe.Measure.drop/2` strips ANSI and `slice/3` preserves it.
- Move runtime infrastructure under the runtime child supervisor.
- Add `Cringe.Layout.focus_ids/1` and `Cringe.Driver.await_text/3`.

## 0.5.0 (2026-05-26)

- Avoid linking public docs to the hidden terminal session implementation.
- Add a form integration test for layout-derived focus navigation.
- Let the runtime own terminal input session startup and shutdown.
- Tighten terminal wrapping edge-case coverage.
- Add ANSI-preserving `Cringe.Measure.slice/3` and use it for clipped canvas writes.

## 0.4.0 (2026-05-26)

- Move terminal input ownership into an internal terminal session.
- Add public terminal-cell chunking and wrapping helpers.

## 0.3.1 (2026-05-26)

- Document `Cringe.Measure` as a public terminal-cell text helper API.
- Add nested overflow and clipped styled text regression coverage.

## 0.3.0 (2026-05-26)

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
- Add a runtime supervisor for OTP-owned app processes.
- Draw stack children from positioned layout geometry.
- Add terminal-cell-aware `Cringe.Measure.fit/3`.
- Add layout focus navigation helpers.
- Add clipped canvas block writes.
- Draw boxes recursively from layout geometry with clipped overflow.
- Stop composing child content into stack and box layout lines.
- Draw text from document content and layout geometry.
- Move repeating runtime ticks into a tick manager process.
- Add a draw context for ANSI and nested clipping state.
- Make stack and box layout sizing geometry-native with explicit node sizes.

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
