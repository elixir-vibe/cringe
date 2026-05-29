defmodule TickingSpinner do
  use Cringe.App

  @impl true
  def init(_opts), do: {:ok, %{frame: 0}}

  @impl true
  def handle_event(%Cringe.Event.Tick{id: :spinner}, state),
    do: {:noreply, %{state | frame: state.frame + 1}}

  def handle_event(%Cringe.Event.Text{text: "q"}, _state), do: {:stop, :normal}
  def handle_event(%Cringe.Event.Key{key: :c, mods: [:ctrl]}, _state), do: {:stop, :normal}

  @impl true
  def render(state) do
    box padding: 1 do
      column gap: 1 do
        text("Ticking Spinner", color: :green, bold: true)
        spinner(frame: state.frame, label: "Working")
        text("q or Ctrl+C quits", color: :bright_black)
      end
    end
  end
end

{:ok, app} =
  Cringe.run(TickingSpinner,
    backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true, takeover: true},
    ticks: [spinner: 100],
    ansi: true
  )

ref = Process.monitor(app)
Cringe.Runtime.paint(app)

receive do
  {:DOWN, ^ref, :process, ^app, _reason} -> :ok
end
