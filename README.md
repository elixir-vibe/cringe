# Cringe

OTP-native terminal UI for Elixir.

Cringe is an experiment in building interactive terminal apps with declarative layouts, supervised runtimes, semantic input events, render-only widgets, and ExUnit-friendly render assertions. The name is a joke; the goal is serious terminal UI ergonomics for the BEAM.

## Status

Early alpha skeleton. The API is not stable yet.

## First document

```elixir
use Cringe

box padding: 1 do
  column gap: 1 do
    text("Cringe", color: :green, bold: true)
    text("Terminal UI for the BEAM")
  end
end
|> render(width: 80, ansi: true)
|> IO.puts()
```

## Render-only widgets

```elixir
use Cringe

column gap: 1 do
  spinner(frame: 2, label: "Loading")
  progress(value: 0.42, width: 16, label: "Build")
  input(value: "cringe", focused: true, width: 24)
  select(options: ["Dashboard", "Logs", "Settings"], selected: 1)
end
```

## Tiny app

```elixir
defmodule Counter do
  use Cringe.App

  def init(_opts), do: {:ok, %{count: 0}}
  def handle_event(%Cringe.Event.Key{key: :up}, state), do: {:noreply, %{state | count: state.count + 1}}
  def render(state), do: box(text("Count: #{state.count}"), padding: 1)
end

{:ok, app} = Cringe.run(Counter, backend: Cringe.Runtime.Backend.Terminal)
Cringe.Runtime.dispatch(app, Cringe.Event.key(:up))
Cringe.Runtime.paint(app)
```

Run examples locally:

```sh
mix run examples/hello.exs
mix run examples/dashboard.exs
mix run examples/layout.exs
mix run examples/dsl.exs
mix run examples/widgets.exs
mix run examples/counter.exs
mix run examples/interactive_counter.exs
mix run examples/interactive_input.exs
mix run examples/form.exs
```

## Installation

Once published, add `cringe` to your dependencies:

```elixir
def deps do
  [
    {:cringe, "~> 0.1"}
  ]
end
```

Documentation will be published at <https://hexdocs.pm/cringe>.
