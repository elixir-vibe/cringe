defmodule Cringe.RuntimeTest do
  use ExUnit.Case, async: true

  defmodule Counter do
    use Cringe.App

    @impl true
    def init(_opts), do: {:ok, %{count: 0}}

    @impl true
    def handle_event({:key, :up}, state), do: {:noreply, %{state | count: state.count + 1}}

    @impl true
    def render(state), do: Cringe.box(Cringe.text("Count: #{state.count}"), padding: 1)
  end

  test "runs app lifecycle and dispatches events" do
    assert {:ok, app} = Cringe.Test.start(Counter)
    assert Cringe.Test.text(app) =~ "Count: 0"

    assert :ok = Cringe.Test.key(app, :up)
    assert Cringe.Test.text(app) =~ "Count: 1"
  end
end
