defmodule LayoutFocusForm do
  use Cringe.App

  alias Cringe.Focus
  alias Cringe.Layout
  alias Cringe.Layout.Engine
  alias Cringe.Widgets.Input
  alias Cringe.Widgets.Input.State, as: InputState

  @impl true
  def init(_opts), do: {:ok, %{focus: Focus.new([:name]), name: InputState.new("")}}

  @impl true
  def handle_event(%Cringe.Event.Key{key: :tab}, state), do: {:noreply, move_focus(state, :next)}

  def handle_event(%Cringe.Event.Key{key: :tab, mods: [:shift]}, state),
    do: {:noreply, move_focus(state, :previous)}

  def handle_event(%Cringe.Event.Key{key: :c, mods: [:ctrl]}, _state), do: {:stop, :normal}
  def handle_event(%Cringe.Event.Text{text: "q"}, _state), do: {:stop, :normal}

  def handle_event(event, state) do
    case Input.update(state.name, event) do
      {:ok, name} -> {:noreply, %{state | name: name}}
      :ignored -> {:noreply, state}
    end
  end

  @impl true
  def render(state), do: document(state)

  defp document(state) do
    box padding: 1 do
      column gap: 1 do
        text("Layout-derived focus", color: :green, bold: true)

        input(
          id: :name,
          state: state.name,
          focused: Focus.focused?(state.focus, :name),
          width: 28
        )

        text("Tab derives focus order from layout. q quits.", color: :bright_black)
      end
    end
  end

  defp move_focus(state, direction) do
    layout = Engine.layout(document(state))
    ids = Layout.focus_ids(layout)
    current = Layout.focus_id(layout, direction, Focus.current(state.focus))

    %{state | focus: Focus.new(ids, current: current)}
  end
end

{:ok, app} =
  Cringe.run(LayoutFocusForm,
    backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true, takeover: true},
    ansi: true
  )

ref = Process.monitor(app)
Cringe.Runtime.paint(app)

receive do
  {:DOWN, ^ref, :process, ^app, _reason} -> :ok
end
