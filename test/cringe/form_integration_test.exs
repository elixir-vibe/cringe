defmodule Cringe.FormIntegrationTest do
  use ExUnit.Case, async: true

  alias Cringe.Driver
  alias Cringe.Focus
  alias Cringe.Layout
  alias Cringe.Layout.Engine
  alias Cringe.Runtime
  alias Cringe.Runtime.Backend.Test
  alias Cringe.Widgets.Input
  alias Cringe.Widgets.Input.State, as: InputState
  alias Cringe.Widgets.Select

  defmodule FormApp do
    use Cringe.App

    @roles ["Admin", "Editor", "Viewer"]

    @impl true
    def init(_opts) do
      {:ok,
       %{
         focus: Focus.new([:name, :email, :role]),
         name: InputState.new(""),
         email: InputState.new(""),
         role: 0,
         submitted: nil
       }}
    end

    @impl true
    def handle_event(%Cringe.Event.Key{key: :tab, mods: [:shift]}, state) do
      {:noreply, move_focus(state, :previous)}
    end

    def handle_event(%Cringe.Event.Key{key: :tab}, state) do
      {:noreply, move_focus(state, :next)}
    end

    def handle_event(%Cringe.Event.Key{key: :enter}, state) do
      {:noreply, %{state | submitted: submitted(state)}}
    end

    def handle_event(event, state) do
      case Focus.current(state.focus) do
        :name -> update_input(state, :name, event)
        :email -> update_input(state, :email, event)
        :role -> update_role(state, event)
      end
    end

    @impl true
    def render(state), do: document(state)

    defp document(state) do
      column gap: 1 do
        input(
          id: :name,
          state: state.name,
          focused: Focus.focused?(state.focus, :name),
          width: 12
        )

        input(
          id: :email,
          state: state.email,
          focused: Focus.focused?(state.focus, :email),
          width: 18
        )

        select(
          id: :role,
          options: @roles,
          selected: state.role,
          focused: Focus.focused?(state.focus, :role)
        )

        text("Submitted: #{state.submitted || "—"}")
      end
    end

    defp move_focus(state, direction) do
      layout = Engine.layout(document(state))
      focus_id = Layout.focus_id(layout, direction, Focus.current(state.focus))
      %{state | focus: Focus.new(Enum.map(Layout.focusable(layout), & &1.id), current: focus_id)}
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

  test "drives a form with layout-derived focus navigation" do
    assert {:ok, app} = Driver.start(FormApp, backend: Test, width: 60, height: 10)

    assert :ok = Driver.text_input(app, "Dan")
    assert :ok = Driver.key(app, :tab)
    assert :ok = Driver.text_input(app, "dan@example.com")
    assert :ok = Driver.key(app, :tab)
    assert :ok = Driver.key(app, :down)
    assert :ok = Driver.key(app, :enter)

    assert Runtime.state(app).submitted == "Dan <dan@example.com> as Editor"

    text = Driver.text(app)

    assert text =~ "> Dan"
    assert text =~ "> dan@example.com"
    assert text =~ "› Editor"
    assert text =~ "Submitted: Dan <dan@example.com> as Editor"
  end
end
