defmodule Counter do
  use Cringe.App

  def init(_opts), do: {:ok, %{count: 0}}

  def handle_event({:key, :up}, state), do: {:noreply, %{state | count: state.count + 1}}

  def render(state), do: Cringe.box(Cringe.text("Count: #{state.count}"), padding: 1)
end

{:ok, app} = Cringe.run(Counter)
IO.puts(Cringe.Runtime.text(app))
Cringe.Runtime.dispatch(app, {:key, :up})
IO.puts("\nAfter :up\n")
IO.puts(Cringe.Runtime.text(app))
