# Cringe

OTP-native terminal UI for Elixir.

Cringe is an experiment in building interactive terminal apps with declarative layouts, supervised runtimes, semantic input events, and snapshot-friendly rendering. The name is a joke; the goal is serious terminal UI ergonomics for the BEAM.

## Status

Early skeleton. The API is not stable yet.

## First document

```elixir
Cringe.box(
  Cringe.column(
    [
      Cringe.text("Cringe"),
      Cringe.text("Terminal UI for the BEAM")
    ],
    gap: 1
  ),
  padding: 1
)
|> Cringe.render(width: 80)
|> IO.puts()
```

Run examples locally:

```sh
mix run examples/hello.exs
mix run examples/dashboard.exs
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
