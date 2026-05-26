defmodule Counter do
  use Cringe.App

  def init(_opts), do: {:ok, %{count: 0}}

  def handle_event(%Cringe.Event.Key{key: :up}, state),
    do: {:noreply, %{state | count: state.count + 1}}

  def render(state), do: box(text("Count: #{state.count}"), padding: 1)
end

{:ok, app} = Cringe.run(Counter)
IO.puts(Cringe.Runtime.text(app))
Cringe.Runtime.dispatch(app, Cringe.Event.key(:up))
IO.puts("\nAfter :up\n")
IO.puts(Cringe.Runtime.text(app))
