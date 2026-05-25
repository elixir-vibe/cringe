defmodule Cringe.RuntimeTest do
  use ExUnit.Case, async: true

  import Cringe.Test, only: [assert_text: 2]

  defmodule Counter do
    use Cringe.App

    @impl true
    def init(_opts), do: {:ok, %{count: 0}}

    @impl true
    def handle_event({:key, :up}, state), do: {:noreply, %{state | count: state.count + 1}}

    @impl true
    def render(state), do: box(text("Count: #{state.count}"), padding: 1)
  end

  test "runs app lifecycle and dispatches events" do
    assert {:ok, app} = Cringe.Test.start(Counter)

    assert_text(app, """
    ╭──────────╮
    │          │
    │ Count: 0 │
    │          │
    ╰──────────╯
    """)

    assert :ok = Cringe.Test.key(app, :up)

    assert_text(app, """
    ╭──────────╮
    │          │
    │ Count: 1 │
    │          │
    ╰──────────╯
    """)
  end

  test "paints rendered text to an IO backend" do
    {:ok, device} = StringIO.open("")

    assert {:ok, app} =
             Cringe.Test.start(Counter,
               backend: {Cringe.Runtime.Backend.IO, device: device}
             )

    assert :ok = Cringe.Runtime.paint(app)
    assert {_input, output} = StringIO.contents(device)

    assert output == Cringe.Runtime.text(app)
  end

  test "accepts a backend module without options" do
    assert {:ok, app} = Cringe.Test.start(Counter, backend: Cringe.Runtime.Backend.Test)

    assert :ok = Cringe.Runtime.paint(app)
    assert [output] = Cringe.Runtime.Backend.Test.frames(app)
    assert output == Cringe.Runtime.text(app)
  end
end
