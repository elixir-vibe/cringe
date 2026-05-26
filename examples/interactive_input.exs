defmodule InteractiveInput do
  use Cringe.App

  alias Cringe.Widgets.Input
  alias Cringe.Widgets.Input.State

  @impl true
  def init(_opts), do: {:ok, %{input: State.new(""), submitted: nil}}

  @impl true
  def handle_event(%Cringe.Event.Key{key: :enter}, state) do
    {:noreply, %{state | submitted: State.value(state.input)}}
  end

  def handle_event(%Cringe.Event.Text{text: "q"}, state) when state.input.value == "",
    do: {:stop, :normal}

  def handle_event(event, state) do
    case Input.update(state.input, event) do
      {:ok, input} -> {:noreply, %{state | input: input}}
      :ignored -> {:noreply, state}
    end
  end

  @impl true
  def render(state) do
    box padding: 1 do
      column gap: 1 do
        text("Interactive Input", color: :green, bold: true)
        input(state: state.input, focused: true, width: 40, placeholder: "Type something...")
        text("Submitted: #{state.submitted || "—"}")
        text("Enter submits. Empty q quits.", color: :bright_black)
      end
    end
  end
end

{:ok, app} =
  Cringe.run(InteractiveInput,
    backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true},
    ansi: true
  )

ref = Process.monitor(app)
Cringe.Runtime.paint(app)

receive do
  {:DOWN, ^ref, :process, ^app, _reason} -> :ok
end
