Mix.install([{:cringe, path: Path.expand("..", __DIR__)}])

alias Cringe.Widgets.Tabs.State

state =
  State.new(
    [
      %{id: :overview, label: "Overview", content: "System is running"},
      %{id: :logs, label: "Logs", content: "No recent errors"},
      %{id: :settings, label: "Settings", content: "Use left/right to switch tabs"}
    ],
    selected: 0
  )

Cringe.tabs(state: state)
|> Cringe.render(ansi: true)
|> IO.puts()
