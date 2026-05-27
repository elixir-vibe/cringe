Mix.install([{:cringe, path: Path.expand("..", __DIR__)}])

alias Cringe.Widgets.Table.State

columns = [
  %{id: :name, label: "Name", width: 16},
  %{id: :status, label: "Status", width: 10},
  %{id: :count, label: "Count", width: 5, align: :right}
]

state =
  State.new(
    [
      %{name: "Workers", status: "running", count: 12},
      %{name: "Queue", status: "idle", count: 0},
      %{name: "Jobs", status: "active", count: 37}
    ],
    selected: 0
  )

Cringe.table(columns: columns, state: state)
|> Cringe.render(ansi: true)
|> IO.puts()
