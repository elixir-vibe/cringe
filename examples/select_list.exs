Mix.install([{:cringe, path: Path.expand("..", __DIR__)}])

alias Cringe.Widgets.SelectList.State

state =
  State.new(
    [
      %{id: :dashboard, label: "Dashboard", description: "Overview and live status"},
      %{id: :sessions, label: "Sessions", description: "Recent terminal UI sessions"},
      %{id: :settings, label: "Settings", description: "Profiles, providers, and keybindings"},
      %{id: :logs, label: "Logs", description: "Runtime diagnostics"}
    ],
    selected: 1,
    max_visible: 3
  )

state
|> Cringe.select_list(width: 72)
|> Cringe.render(ansi: true)
|> IO.puts()
