Mix.install([{:cringe, path: Path.expand("..", __DIR__)}])

alias Cringe.Widgets.Editor.State

state = State.new("Write notes here\nUse arrows to move", cursor_line: 1, cursor_col: 3)

state
|> Cringe.editor(focused: true, width: 48)
|> Cringe.render(ansi: true)
|> IO.puts()
