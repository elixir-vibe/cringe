alias Cringe.Widgets.Input
alias Cringe.Widgets.Input.State

state = State.new("hello", cursor: 5)

Benchee.run(
  %{
    "insert" => fn -> Input.update(state, Cringe.Event.text("x")) end,
    "backspace" => fn -> Input.update(state, Cringe.Event.key(:backspace)) end,
    "left" => fn -> Input.update(state, Cringe.Event.key(:left)) end,
    "string insert" => fn -> Input.update("hello", Cringe.Event.text("x")) end
  },
  time: 1,
  memory_time: 0.2
)
