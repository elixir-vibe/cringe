Mix.install([{:cringe, path: Path.expand("..", __DIR__)}])

alias Cringe.Widgets.Form.Field
alias Cringe.Widgets.Form.State

state =
  State.new([
    Field.input(:name, value: "Dan", width: 28),
    Field.editor(:notes, value: "Multiline\nnotes", width: 28, height: 2),
    Field.select(:role, ["Admin", "Editor", "Viewer"], selected: 1)
  ])

state
|> Cringe.form()
|> Cringe.render(ansi: true)
|> IO.puts()
