defmodule FormExample do
  use Cringe.App

  alias Cringe.Focus
  alias Cringe.Widgets.Input
  alias Cringe.Widgets.Input.State, as: InputState
  alias Cringe.Widgets.Select

  @roles ["Admin", "Editor", "Viewer"]
  @fields [:name, :email, :role]

  @impl true
  def init(_opts) do
    {:ok,
     %{
       focus: Focus.new(@fields),
       name: InputState.new(""),
       email: InputState.new(""),
       role: 0,
       submitted: nil
     }}
  end

  @impl true
  def handle_event(%Cringe.Event.Key{key: :tab, mods: [:shift]}, state),
    do: {:noreply, %{state | focus: Focus.previous(state.focus)}}

  def handle_event(%Cringe.Event.Key{key: :tab}, state),
    do: {:noreply, %{state | focus: Focus.next(state.focus)}}

  def handle_event(%Cringe.Event.Key{key: :enter}, state),
    do: {:noreply, %{state | submitted: submitted(state)}}

  def handle_event(%Cringe.Event.Key{key: :c, mods: [:ctrl]}, _state), do: {:stop, :normal}

  def handle_event(%Cringe.Event.Text{text: "q"}, state)
      when state.name.value == "" and state.email.value == "", do: {:stop, :normal}

  def handle_event(event, state) do
    case Focus.current(state.focus) do
      :name -> update_input(state, :name, event)
      :email -> update_input(state, :email, event)
      :role -> update_role(state, event)
    end
  end

  @impl true
  def render(state) do
    box padding: 1 do
      column gap: 1 do
        text("Cringe Form", color: :green, bold: true)

        input(
          state: state.name,
          focused: Focus.focused?(state.focus, :name),
          width: 36,
          placeholder: "Name"
        )

        input(
          state: state.email,
          focused: Focus.focused?(state.focus, :email),
          width: 36,
          placeholder: "Email"
        )

        select(options: @roles, selected: state.role, focused: Focus.focused?(state.focus, :role))
        text("Submitted: #{state.submitted || "—"}")
        text("Tab cycles, Enter submits, empty q quits", color: :bright_black)
      end
    end
  end

  defp update_input(state, field, event) do
    case Input.update(Map.fetch!(state, field), event) do
      {:ok, input} -> {:noreply, Map.put(state, field, input)}
      :ignored -> {:noreply, state}
    end
  end

  defp update_role(state, event) do
    case Select.update(state.role, event, @roles) do
      {:ok, role} -> {:noreply, %{state | role: role}}
      :ignored -> {:noreply, state}
    end
  end

  defp submitted(state) do
    role = Enum.at(@roles, state.role)
    "#{state.name.value} <#{state.email.value}> as #{role}"
  end
end

{:ok, app} =
  Cringe.run(FormExample,
    backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true, takeover: true},
    ansi: true
  )

ref = Process.monitor(app)
Cringe.Runtime.paint(app)

receive do
  {:DOWN, ^ref, :process, ^app, _reason} -> :ok
end
