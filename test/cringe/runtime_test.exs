defmodule Cringe.RuntimeTest do
  use ExUnit.Case, async: true

  import Cringe.Assertions, only: [assert_app_text: 2]

  alias Cringe.Driver
  alias Cringe.Runtime
  alias Cringe.Runtime.Backend.{IO, Terminal, Test}

  defmodule Counter do
    use Cringe.App

    @impl true
    def init(_opts), do: {:ok, %{count: 0}}

    @impl true
    def handle_event(%Cringe.Event.Key{key: :up}, state),
      do: {:noreply, %{state | count: state.count + 1}}

    def handle_event(%Cringe.Event.Resize{} = event, state),
      do: {:noreply, Map.put(state, :last_resize, event)}

    def handle_event(%Cringe.Event.Tick{id: id}, state),
      do: {:noreply, Map.update(state, {:tick, id}, 1, &(&1 + 1))}

    @impl true
    def render(state), do: box(text("Count: #{state.count}"), padding: 1)
  end

  defmodule FakeTerminalSession do
    use GenServer

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    def write(session, output), do: GenServer.call(session, {:write, output})

    @impl true
    def init(opts), do: {:ok, %{owner: Keyword.fetch!(opts, :owner), writes: []}}

    @impl true
    def handle_call({:write, output}, _from, state) do
      {:reply, :ok, %{state | writes: [Elixir.IO.iodata_to_binary(output) | state.writes]}}
    end
  end

  test "runs app lifecycle and dispatches events" do
    assert {:ok, app} = Driver.start(Counter)

    assert_app_text(app, """
    ╭──────────╮
    │          │
    │ Count: 0 │
    │          │
    ╰──────────╯
    """)

    assert :ok = Driver.key(app, :up)

    assert_app_text(app, """
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
             Driver.start(Counter,
               backend: {IO, device: device}
             )

    assert :ok = Runtime.paint(app)
    assert {_input, output} = StringIO.contents(device)

    assert output =~ "\e[H\e[2J"
    assert output =~ "Count: 0"
  end

  test "accepts a backend module without options" do
    assert {:ok, app} = Driver.start(Counter, backend: Test)

    assert :ok = Runtime.paint(app)
    assert [output] = Test.frames(app)
    assert output =~ "\e[H\e[2J"
    assert output =~ "Count: 0"
  end

  test "skips backend writes when a repaint has no changed lines" do
    assert {:ok, app} = Driver.start(Counter, backend: Test)

    assert :ok = Runtime.paint(app)
    assert :ok = Runtime.paint(app)

    assert [_first_output] = Test.frames(app)
  end

  test "subsequent paints write changed lines only" do
    assert {:ok, app} = Driver.start(Counter, backend: Test)

    assert :ok = Runtime.paint(app)
    assert :ok = Driver.key(app, :up)
    assert :ok = Runtime.paint(app)

    assert [_first_output, next_output] = Test.frames(app)
    assert next_output =~ "Count: 1"
    refute next_output =~ "\e[H\e[2J"
  end

  test "terminal backend manages terminal presentation sequences" do
    {:ok, device} = StringIO.open("")

    assert {:ok, app} =
             Driver.start(Counter,
               backend: {Terminal, device: device, alternate_screen: true}
             )

    assert :ok = Runtime.paint(app)
    assert :ok = GenServer.stop(app)
    assert {_input, output} = StringIO.contents(device)

    assert output =~ "\e[?1049h"
    assert output =~ "\e[?7l"
    assert output =~ "\e[?25l"
    assert output =~ "Count: 0"
    assert output =~ "\e[?25h"
    assert output =~ "\e[?7h"
    assert output =~ "\e[?1049l"
  end

  test "terminal backend avoids painting the final column" do
    {:ok, device} = StringIO.open("")

    assert {:ok, app} =
             Driver.start(Counter,
               backend: {Terminal, device: device},
               width: 12,
               height: 5
             )

    assert :ok = Runtime.paint(app)
    assert {_input, output} = StringIO.contents(device)

    refute output =~ "╭──────────╮"
    assert output =~ "╭──────────"
  end

  test "decodes terminal input and repaints" do
    assert {:ok, app} = Driver.start(Counter, backend: Test)

    assert :ok = Runtime.input(app, "\e[A")
    assert %{count: 1} = Runtime.state(app)
    assert [output] = Test.frames(app)
    assert output =~ "Count: 1"
  end

  test "renders overlays above app documents" do
    assert {:ok, app} = Driver.start(Counter, width: 24, height: 7)

    assert :ok = Runtime.show_overlay(app, :dialog, Cringe.text("Overlay"), anchor: :center)

    text = Runtime.text(app)

    assert text =~ "Count: 0"
    assert text =~ "Overlay"
  end

  test "paints overlay changes immediately" do
    assert {:ok, app} = Driver.start(Counter, backend: Test, width: 24, height: 7)

    assert :ok = Runtime.paint(app)
    assert :ok = Runtime.show_overlay(app, :dialog, Cringe.text("Overlay"), anchor: :center)
    assert [_initial, overlay_output] = Test.frames(app)
    assert overlay_output =~ "Overlay"
  end

  test "hides and clears runtime overlays" do
    assert {:ok, app} = Driver.start(Counter, width: 24, height: 7)

    assert :ok = Runtime.show_overlay(app, :one, Cringe.text("One"))
    assert :ok = Runtime.show_overlay(app, :two, Cringe.text("Two"), capture?: false)
    assert [:one, :two] = app |> Runtime.overlays() |> Map.fetch!(:layers) |> Enum.map(& &1.id)

    assert :ok = Runtime.hide_overlay(app, :one)
    assert [:two] = app |> Runtime.overlays() |> Map.fetch!(:layers) |> Enum.map(& &1.id)

    assert :ok = Runtime.clear_overlays(app)
    assert Runtime.overlays(app).layers == []
  end

  test "handles Ghostty TTY key messages and repaints" do
    assert {:ok, app} = Driver.start(Counter, backend: Test)

    send(app, {Ghostty.TTY, self(), {:key, %Ghostty.KeyEvent{action: :press, key: :arrow_up}}})

    assert Driver.await_state(app, &(&1.count == 1))
    assert [output] = Test.frames(app)
    assert output =~ "Count: 1"
  end

  test "handles Ghostty TTY resize messages" do
    assert {:ok, app} = Driver.start(Counter, backend: Test)

    send(app, {Ghostty.TTY, self(), {:resize, 12, 4}})

    assert Driver.await_frame(app, &String.contains?(&1, "Count"))
    assert [%{width: 12, height: 4}] = [Runtime.state(app) |> Map.get(:last_resize)]
  end

  test "dispatches configured tick events and repaints" do
    assert {:ok, app} = Driver.start(Counter, backend: Test, ticks: [spinner: 10])

    assert Driver.await_state(app, & &1[{:tick, :spinner}])
    assert Test.frames(app) != []
  end

  test "driver dispatches key sequences" do
    assert {:ok, app} = Driver.start(Counter)

    assert :ok = Driver.keys(app, [:up, :up])
    assert Runtime.state(app).count == 2
  end

  test "can run under a runtime supervisor" do
    assert {:ok, supervisor} = Cringe.run_supervised(Counter)
    assert app = Cringe.Runtime.Supervisor.runtime(supervisor)

    assert :ok = Driver.key(app, :up)
    assert Runtime.state(app).count == 1
  end

  test "runtime supervisor owns runtime child processes" do
    assert {:ok, supervisor} =
             Cringe.run_supervised(Counter, backend: Test, ticks: [spinner: 1_000])

    assert child_supervisor = Cringe.Runtime.Supervisor.child_supervisor(supervisor)

    assert [{_, tick_manager, :worker, [Cringe.Runtime.TickManager]}] =
             DynamicSupervisor.which_children(child_supervisor)

    assert is_pid(tick_manager)
  end

  test "runtime supervisor owns terminal session child process" do
    assert {:ok, supervisor} =
             Cringe.run_supervised(Counter,
               backend: {Terminal, input: true, terminal_session_module: FakeTerminalSession}
             )

    assert child_supervisor = Cringe.Runtime.Supervisor.child_supervisor(supervisor)

    assert [{_, terminal_session, :worker, [FakeTerminalSession]}] =
             DynamicSupervisor.which_children(child_supervisor)

    assert %{terminal_session: ^terminal_session} =
             supervisor |> Cringe.Runtime.Supervisor.runtime() |> Runtime.backend_state()
  end
end
