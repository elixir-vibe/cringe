# Cringe

OTP-native terminal UI toolkit for Elixir.

Cringe helps you build terminal interfaces with plain Elixir data, supervised processes, semantic input events, and ExUnit-friendly rendering. The name is a joke; the goal is serious terminal UI ergonomics for the BEAM.

```elixir
use Cringe

box padding: 1 do
  column gap: 1 do
    text("Cringe", color: :green, bold: true)
    text("Terminal UI for Elixir")
    progress(value: 0.42, width: 16, label: "Build")
  end
end
|> render(ansi: true)
|> IO.puts()
```

## Status

Cringe is early alpha. It is useful for experiments, demos, small tools, and for exploring terminal UI design on the BEAM. APIs may change before `1.0`.

## Why Cringe?

- **Plain Elixir documents** — compose text, rows, columns, boxes, and widgets without a template language.
- **OTP-native runtime** — apps are regular supervised processes with explicit state and event handling.
- **Ghostty-backed terminal input** — keyboard decoding and current-terminal integration use the `ghostty` package instead of hand-rolled TTY parsing.
- **Semantic events** — apps handle `%Cringe.Event.Key{}`, `%Cringe.Event.Text{}`, `%Cringe.Event.Resize{}`, and `%Cringe.Event.Tick{}`.
- **Testable rendering** — assert terminal output with normal ExUnit heredocs.
- **Small widget layer** — render inputs, selects, progress bars, and spinners while keeping app state explicit.
- **Canvas + painter pipeline** — render fixed-size frames and repaint changed lines efficiently.

## Installation

Add `cringe` to your dependencies:

```elixir
def deps do
  [
    {:cringe, "~> 0.5.0"}
  ]
end
```

Documentation: <https://hexdocs.pm/cringe>

## Documents

Import the DSL with `use Cringe` or `import Cringe`:

```elixir
use Cringe

column gap: 1 do
  text("Deploy", color: :green, bold: true)
  text("Building assets")
  progress(value: 0.7, width: 20)
end
|> render(ansi: true)
```

Core building blocks:

```elixir
text("hello", color: :green, bold: true)
row([text("left"), text("right")], gap: 2)
column([text("one"), text("two")], gap: 1)
box(text("inside"), padding: 1)
```

Block syntax is available for containers:

```elixir
box padding: 1 do
  column gap: 1 do
    text("Title")
    text("Body")
  end
end
```

## Widgets

Widgets are render-only by default. You keep state in your app and pass it in explicitly.

Stateful widgets follow the same contract:

- state lives in a struct-backed `State` module
- `new/1` builds a document from options
- `render/2` is a state-first wrapper around `new/1`
- `update/2` uses default keybindings
- `update/3` accepts a custom `Cringe.Keymap` where supported
- update results are `{:ok, state}`, `{:select, item, state}`, `{:cancel, state}`, or `:ignored`

Apps decide what selection, cancellation, submission, validation, history, and autocomplete mean.

```elixir
column gap: 1 do
  spinner(frame: 2, label: "Loading")
  progress(value: 0.42, width: 16, label: "Build")
  input(value: "cringe", focused: true, width: 24)
  select(options: ["Dashboard", "Logs", "Settings"], selected: 1, focused: true)
end
```

For richer pickers, use `Cringe.Widgets.SelectList` with explicit item and state structs:

```elixir
alias Cringe.Widgets.SelectList
alias Cringe.Widgets.SelectList.State

state =
  State.new([
    %{id: :dashboard, label: "Dashboard", description: "Overview and live status"},
    %{id: :settings, label: "Settings", description: "Profiles and keybindings"}
  ])

{:ok, state} = SelectList.update(state, Cringe.Event.key(:down))
select_list(state: state, width: 72)
```

Cursor-aware input state is available when you need editing behavior:

```elixir
alias Cringe.Widgets.Input
alias Cringe.Widgets.Input.State

state = State.new("hello", cursor: 5)
{:ok, state} = Input.update(state, Cringe.Event.text("!"))
```

For multiline text, `Cringe.Widgets.Editor` keeps cursor position in a state struct:

```elixir
alias Cringe.Widgets.Editor
alias Cringe.Widgets.Editor.State

state = State.new("one\ntwo", cursor_line: 1, cursor_col: 3)
{:ok, state} = Editor.update(state, Cringe.Event.key(:enter))
editor(state: state, focused: true, height: 4)
```

Selects expose the same explicit update style:

```elixir
alias Cringe.Widgets.Select

{:ok, selected} = Select.update(0, Cringe.Event.key(:down), ["one", "two"])
```

Widgets can use keymaps to keep shortcuts semantic and configurable:

```elixir
keymap = Cringe.Keymap.new(next: [:tab], cancel: [:escape, {:c, [:ctrl]}])
Cringe.Keymap.match?(keymap, :cancel, Cringe.Event.key(:c, mods: [:ctrl]))
```

`Cringe.Widgets.Menu` renders generic action menus with sections, separators,
shortcuts, descriptions, and disabled items:

```elixir
alias Cringe.Widgets.Menu.State

state =
  State.new([
    {:section, "File"},
    %{id: :open, label: "Open", shortcut: "Enter", description: "Open item"},
    :separator,
    %{id: :delete, label: "Delete", disabled?: true}
  ])

menu(state: state, width: 64)
```

`Cringe.Widgets.Dialog` provides generic title/body/action rendering and action
selection:

```elixir
alias Cringe.Widgets.Dialog
alias Cringe.Widgets.Dialog.State

state = State.new([%{id: :cancel, label: "Cancel"}, %{id: :ok, label: "OK"}])
{:ok, state} = Dialog.update(state, Cringe.Event.key(:right))
dialog(title: "Continue?", body: "Run the operation.", state: state)
```

`Cringe.Widgets.Tabs` renders a selected panel from struct-backed tab state:

```elixir
alias Cringe.Widgets.Tabs.State

state =
  State.new([
    %{id: :overview, label: "Overview", content: "System is running"},
    %{id: :logs, label: "Logs", content: "No errors"}
  ])

tabs(state: state)
```

`Cringe.Widgets.Table` renders fixed columns with optional row selection:

```elixir
alias Cringe.Widgets.Table.State

columns = [%{id: :name, label: "Name", width: 12}, %{id: :count, label: "Count", align: :right}]
state = State.new([%{name: "Jobs", count: 37}], selected: 0)
table(columns: columns, state: state)
```

`Cringe.Widgets.Form` is a generic focused field container. It owns focus and
delegates input to field widgets without imposing submission or validation rules:

```elixir
alias Cringe.Widgets.Form
alias Cringe.Widgets.Form.Field
alias Cringe.Widgets.Form.State

state =
  State.new([
    Field.input(:name, width: 28),
    Field.editor(:notes, width: 28, height: 2),
    Field.select(:role, ["Admin", "Editor", "Viewer"])
  ])

{:ok, state} = Form.update(state, Cringe.Event.key(:tab))
form(state: state)
```

## Interactive apps

Cringe apps are modules that use `Cringe.App`:

```elixir
defmodule Counter do
  use Cringe.App

  def init(_opts), do: {:ok, %{count: 0}}

  def handle_event(%Cringe.Event.Key{key: :up}, state),
    do: {:noreply, %{state | count: state.count + 1}}

  def handle_event(%Cringe.Event.Key{key: :down}, state),
    do: {:noreply, %{state | count: state.count - 1}}

  def handle_event(%Cringe.Event.Text{text: "q"}, _state),
    do: {:stop, :normal}

  def render(state) do
    box padding: 1 do
      column gap: 1 do
        text("Counter", color: :green, bold: true)
        text("Count: #{state.count}")
        text("Use arrows, q quits", color: :bright_black)
      end
    end
  end
end

{:ok, app} =
  Cringe.run(Counter,
    backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true},
    ansi: true
  )

Cringe.Runtime.paint(app)
```

The terminal backend uses `Ghostty.TTY` for current-terminal input when running against `:stdio`.

For OTP trees, start the runtime under its supervisor:

```elixir
{:ok, supervisor} = Cringe.run_supervised(Counter, ansi: true)
app = Cringe.Runtime.Supervisor.runtime(supervisor)
```

## Layout regions and focus

Layout nodes preserve document IDs, roles, focusability, and coordinates:

```elixir
layout =
  box padding: 1 do
    input(id: :name, value: "Dan")
  end
  |> Cringe.Layout.Engine.layout()

Cringe.Layout.find(layout, :name)
Cringe.Layout.at(layout, 2, 2)
Cringe.Layout.path_at(layout, 2, 2)
Cringe.Layout.focusable(layout)
```

`Cringe.Focus` is a tiny deterministic focus ring:

```elixir
focus = Cringe.Focus.new([:name, :email, :role])
focus = Cringe.Focus.next(focus)
Cringe.Focus.focused?(focus, :email)
```

The form example shows this with inputs and selects.

## Overlays

`Cringe.Overlay` composes documents without imposing runtime policy:

```elixir
overlays =
  Cringe.Overlay.new([
    Cringe.Overlay.layer(:dialog, dialog(title: "Continue?", actions: [%{id: :ok, label: "OK"}]),
      anchor: :center,
      capture?: true
    )
  ])

Cringe.Overlay.render(text("base"), overlays, width: 80, height: 24)
```

Layers are ordered bottom-to-top. Use `Cringe.Overlay.State.capturing/1` if an
app wants to route input to the topmost capturing layer.

The runtime can also own overlay state and repaint immediately:

```elixir
Cringe.Runtime.show_overlay(app, :dialog, dialog(title: "Continue?"), anchor: :center)
Cringe.Runtime.hide_overlay(app, :dialog)
Cringe.Runtime.clear_overlays(app)
```

## Architecture

Cringe keeps each terminal UI stage explicit:

```text
Document -> Layout.Node tree -> Draw/Canvas -> Frame -> Painter -> Backend
```

- Documents are plain Elixir structs built with functions or the DSL.
- Layout computes positioned nodes, sizes, content rectangles, cursors, focus metadata, and hit regions.
- Draw turns the layout tree into a fixed-size canvas and frame.
- The painter compares frames and emits terminal updates.
- Backends write updates to tests, IO devices, or the current terminal.

This split keeps app state semantic and makes rendering deterministic in tests.

## Testing

Cringe test helpers keep expected terminal output readable in normal ExUnit assertions:

```elixir
defmodule MyUITest do
  use ExUnit.Case, async: true

  use Cringe.Case

  test "renders a box" do
    assert_render box(text("hi"), padding: 1), """
    ╭────╮
    │    │
    │ hi │
    │    │
    ╰────╯
    """
  end
end
```

For apps:

```elixir
{:ok, app} = Cringe.Driver.start(Counter)
Cringe.Driver.keys(app, [:up, :up])

assert Cringe.Driver.await_state(app, &(&1.count == 2))
assert_app_text(app, "...")
```

`Cringe.Driver.await_frame/3` is useful when testing async terminal input, resize, or tick-driven repaint behavior.

## Examples

Run examples locally:

```sh
mix run examples/hello.exs
mix run examples/dashboard.exs
mix run examples/layout.exs
mix run examples/dsl.exs
mix run examples/widgets.exs
mix run examples/counter.exs
mix run examples/dialog.exs
mix run examples/editor.exs
mix run examples/generic_form.exs
mix run examples/interactive_counter.exs
mix run examples/interactive_input.exs
mix run examples/form.exs
mix run examples/layout_focus_form.exs
mix run examples/menu.exs
mix run examples/select_list.exs
mix run examples/table.exs
mix run examples/tabs.exs
mix run examples/ticking_spinner.exs
```

The interactive examples use the terminal backend. `q` or Ctrl+C exits where supported.

## Benchmarks

Cringe includes local Benchee benchmarks for render, canvas, painter, and input paths:

```sh
mix bench
```

Benchmarks are for local regression checks and are not part of CI.

## Development

```sh
mix deps.get
mix ci
```

## License

MIT © 2026 Danila Poyarkov
