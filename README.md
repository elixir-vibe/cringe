# Cringe

OTP-native terminal UI for Elixir.

Cringe is an experiment in building interactive terminal apps with declarative layouts, supervised runtimes, semantic input events, and snapshot-friendly rendering. The name is a joke; the goal is serious terminal UI ergonomics for the BEAM.

## Status

Early alpha skeleton. The API is not stable yet.

## First document

```elixir
Cringe.box(
  Cringe.column(
    [
      Cringe.text("Cringe", color: :green, bold: true),
      Cringe.text("Terminal UI for the BEAM")
    ],
    gap: 1
  ),
  padding: 1
)
|> Cringe.render(width: 80, ansi: true)
|> IO.puts()
```

## Tiny app

```elixir
defmodule Counter do
  use Cringe.App

  def init(_opts), do: {:ok, %{count: 0}}
  def handle_event({:key, :up}, state), do: {:noreply, %{state | count: state.count + 1}}
  def render(state), do: Cringe.box(Cringe.text("Count: #{state.count}"), padding: 1)
end

{:ok, app} = Cringe.run(Counter)
Cringe.Runtime.dispatch(app, {:key, :up})
IO.puts(Cringe.Runtime.text(app))
```

Run examples locally:

```sh
mix run examples/hello.exs
mix run examples/dashboard.exs
mix run examples/layout.exs
mix run examples/counter.exs
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
