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

  test "paints rendered text to an IO backend through the frame painter" do
    {:ok, device} = StringIO.open("")

    assert {:ok, app} =
             Cringe.Test.start(Counter,
               backend: {Cringe.Runtime.Backend.IO, device: device}
             )

    assert :ok = Cringe.Runtime.paint(app)
    assert {_input, output} = StringIO.contents(device)

    assert output =~ "\e[H\e[2J"
    assert output =~ "Count: 0"
  end

  test "accepts a backend module without options" do
    assert {:ok, app} = Cringe.Test.start(Counter, backend: Cringe.Runtime.Backend.Test)

    assert :ok = Cringe.Runtime.paint(app)
    assert [output] = Cringe.Runtime.Backend.Test.frames(app)
    assert output =~ "\e[H\e[2J"
    assert output =~ "Count: 0"
  end

  test "skips backend writes when a repaint has no changed lines" do
    assert {:ok, app} = Cringe.Test.start(Counter, backend: Cringe.Runtime.Backend.Test)

    assert :ok = Cringe.Runtime.paint(app)
    assert :ok = Cringe.Runtime.paint(app)

    assert [_first_output] = Cringe.Runtime.Backend.Test.frames(app)
  end

  test "subsequent paints write changed lines only" do
    assert {:ok, app} = Cringe.Test.start(Counter, backend: Cringe.Runtime.Backend.Test)

    assert :ok = Cringe.Runtime.paint(app)
    assert :ok = Cringe.Test.key(app, :up)
    assert :ok = Cringe.Runtime.paint(app)

    assert [_first_output, next_output] = Cringe.Runtime.Backend.Test.frames(app)
    assert next_output =~ "Count: 1"
    refute next_output =~ "\e[H\e[2J"
  end
end
