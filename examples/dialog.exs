Mix.install([{:cringe, path: Path.expand("..", __DIR__)}])

alias Cringe.Widgets.Dialog.State

state =
  State.new([%{id: :cancel, label: "Cancel"}, %{id: :continue, label: "Continue"}], selected: 1)

state
|> Cringe.dialog(
  title: "Continue?",
  body: "Run the selected operation and close this dialog.",
  width: 42
)
|> Cringe.render(ansi: true)
|> IO.puts()
