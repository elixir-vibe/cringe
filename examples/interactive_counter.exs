defmodule InteractiveCounter do
  use Cringe.App

  @impl true
  def init(_opts), do: {:ok, %{count: 0}}

  @impl true
  def handle_event(%Cringe.Event.Key{key: key}, state) when key in [:up, :right],
    do: {:noreply, %{state | count: state.count + 1}}

  def handle_event(%Cringe.Event.Text{text: text}, state) when text in ["+", "="],
    do: {:noreply, %{state | count: state.count + 1}}

  def handle_event(%Cringe.Event.Key{key: key}, state) when key in [:down, :left],
    do: {:noreply, %{state | count: state.count - 1}}

  def handle_event(%Cringe.Event.Text{text: "-"}, state),
    do: {:noreply, %{state | count: state.count - 1}}

  def handle_event(%Cringe.Event.Text{text: "q"}, _state), do: {:stop, :normal}
  def handle_event(%Cringe.Event.Key{key: :c, mods: [:ctrl]}, _state), do: {:stop, :normal}

  @impl true
  def render(state) do
    box padding: 1 do
      column gap: 1 do
        text("Interactive Counter", color: :green, bold: true)
        text("Count: #{state.count}")
        text("Use arrows/+/- to change, q or Ctrl+C to quit")
      end
    end
  end
end

{:ok, app} =
  Cringe.run(InteractiveCounter,
    backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true},
    ansi: true
  )

ref = Process.monitor(app)
Cringe.Runtime.paint(app)

receive do
  {:DOWN, ^ref, :process, ^app, _reason} -> :ok
end
