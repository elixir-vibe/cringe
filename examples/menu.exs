Mix.install([{:cringe, path: Path.expand("..", __DIR__)}])

alias Cringe.Widgets.Menu.State

state =
  State.new([
    {:section, "File"},
    %{id: :open, label: "Open", shortcut: "Enter", description: "Open selected item"},
    %{id: :rename, label: "Rename", shortcut: "r", description: "Rename item"},
    :separator,
    %{id: :delete, label: "Delete", shortcut: "d", disabled?: true}
  ])

Cringe.menu(state: state, width: 64)
|> Cringe.render(ansi: true)
|> IO.puts()
