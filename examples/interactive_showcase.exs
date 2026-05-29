defmodule InteractiveShowcase do
  use Cringe.App

  alias Cringe.Focus
  alias Cringe.Widgets.Dialog
  alias Cringe.Widgets.Dialog.State, as: DialogState
  alias Cringe.Widgets.Editor
  alias Cringe.Widgets.Editor.State, as: EditorState
  alias Cringe.Widgets.Form
  alias Cringe.Widgets.Form.Field
  alias Cringe.Widgets.Form.State, as: FormState
  alias Cringe.Widgets.Menu
  alias Cringe.Widgets.Menu.State, as: MenuState
  alias Cringe.Widgets.SelectList
  alias Cringe.Widgets.SelectList.State, as: SelectListState
  alias Cringe.Widgets.Table
  alias Cringe.Widgets.Table.State, as: TableState
  alias Cringe.Widgets.Tabs
  alias Cringe.Widgets.Tabs.State, as: TabsState

  @panes [:menu, :select_list, :table, :form, :tabs, :editor]

  @impl true
  def init(_opts) do
    {:ok,
     %{
       focus: Focus.new(@panes),
       menu: menu_state(),
       select_list: select_state(),
       table: table_state(),
       form: form_state(),
       tabs: tabs_state(),
       editor: EditorState.new("abcdef", cursor_col: 5),
       dialog: nil,
       status: "Tab/Shift+Tab panes · arrows edit · Enter selects · o overlay · q quits"
     }}
  end

  @impl true
  def handle_event(%Cringe.Event.Key{key: :c, mods: [:ctrl]}, _state), do: {:stop, :normal}
  def handle_event(%Cringe.Event.Text{text: "q"}, _state), do: {:stop, :normal}
  def handle_event(%Cringe.Event.Text{text: "o"}, state), do: {:noreply, toggle_dialog(state)}

  def handle_event(%Cringe.Event.Key{key: :tab, mods: [:shift]}, state),
    do: {:noreply, %{state | focus: Focus.previous(state.focus)}}

  def handle_event(%Cringe.Event.Key{key: :tab}, state),
    do: {:noreply, %{state | focus: Focus.next(state.focus)}}

  def handle_event(event, %{dialog: %DialogState{} = dialog} = state) do
    case Dialog.update(dialog, event) do
      {:ok, dialog} ->
        {:noreply, %{state | dialog: dialog}}

      {:select, action, _dialog} ->
        {:noreply, %{state | dialog: nil, status: "Dialog selected #{action.label}"}}

      {:cancel, _dialog} ->
        {:noreply, %{state | dialog: nil, status: "Dialog cancelled"}}

      :ignored ->
        route_to_focused(event, state)
    end
  end

  def handle_event(event, state), do: route_to_focused(event, state)

  @impl true
  def render(state) do
    document = base_document(state)

    case state.dialog do
      nil ->
        document

      %DialogState{} = dialog ->
        overlay =
          Cringe.Overlay.layer(:dialog, dialog_document(dialog),
            anchor: :center,
            width: 44,
            capture?: true
          )

        Cringe.Overlay.render(document, Cringe.Overlay.new([overlay]),
          width: 80,
          height: 24,
          ansi: true
        )
        |> Cringe.text()
    end
  end

  defp route_to_focused(event, state) do
    case Focus.current(state.focus) do
      :menu -> update_menu(event, state)
      :select_list -> update_select(event, state)
      :table -> update_table(event, state)
      :form -> update_form(event, state)
      :tabs -> update_tabs(event, state)
      :editor -> update_editor(event, state)
    end
  end

  defp update_menu(event, state) do
    case Menu.update(state.menu, event) do
      {:ok, menu} -> {:noreply, %{state | menu: menu}}
      {:select, item, _menu} -> {:noreply, %{state | status: "Menu selected #{item.label}"}}
      {:cancel, _menu} -> {:noreply, %{state | status: "Menu cancelled"}}
      :ignored -> {:noreply, state}
    end
  end

  defp update_select(event, state) do
    case SelectList.update(state.select_list, event) do
      {:ok, select_list} ->
        {:noreply, %{state | select_list: select_list}}

      {:select, item, _select_list} ->
        {:noreply, %{state | status: "SelectList selected #{item.label}"}}

      {:cancel, _select_list} ->
        {:noreply, %{state | status: "SelectList cancelled"}}

      :ignored ->
        {:noreply, state}
    end
  end

  defp update_table(event, state) do
    case Table.update(state.table, event) do
      {:ok, table} -> {:noreply, %{state | table: table}}
      {:select, row, _table} -> {:noreply, %{state | status: "Table selected #{row.cells.name}"}}
      :ignored -> {:noreply, state}
    end
  end

  defp update_form(event, state) do
    case Form.update(state.form, event) do
      {:ok, form} -> {:noreply, %{state | form: form}}
      :ignored -> {:noreply, state}
    end
  end

  defp update_tabs(event, state) do
    case Tabs.update(state.tabs, event) do
      {:ok, tabs} -> {:noreply, %{state | tabs: tabs}}
      {:select, tab, _tabs} -> {:noreply, %{state | status: "Tab selected #{tab.label}"}}
      :ignored -> {:noreply, state}
    end
  end

  defp update_editor(event, state) do
    case Editor.update(state.editor, event) do
      {:ok, editor} -> {:noreply, %{state | editor: editor}}
      :ignored -> {:noreply, state}
    end
  end

  defp toggle_dialog(%{dialog: nil} = state),
    do: %{state | dialog: dialog_state(), status: "Overlay opened"}

  defp toggle_dialog(state), do: %{state | dialog: nil, status: "Overlay closed"}

  defp base_document(state) do
    column gap: 1 do
      box padding: 1, width: 80 do
        column gap: 0 do
          text("Interactive Cringe", color: :green, bold: true)
          text("Focused: #{Focus.current(state.focus)}")
          text(state.status, color: :bright_black, width: 74)
        end
      end

      row gap: 1, width: 80 do
        pane_list(state)
        active_pane(state)
      end
    end
  end

  defp pane_list(state) do
    box padding: 1, width: 18 do
      column gap: 0 do
        text("Panes", bold: true)
        pane_name(:menu, state)
        pane_name(:select_list, state)
        pane_name(:table, state)
        pane_name(:form, state)
        pane_name(:tabs, state)
        pane_name(:editor, state)
        text("")
        text("o overlay")
        text("q quit")
      end
    end
  end

  defp pane_name(id, state) do
    marker = if Focus.focused?(state.focus, id), do: "› ", else: "  "
    style = if Focus.focused?(state.focus, id), do: Cringe.Style.variant(:selected, []), else: []
    text(marker <> to_string(id), style)
  end

  defp active_pane(state) do
    box padding: 1, width: 61, height: 14, overflow: :hidden do
      column gap: 1 do
        active_title(state)
        active_widget(state)
      end
    end
  end

  defp active_title(state), do: text("#{Focus.current(state.focus)}", bold: true)

  defp active_widget(%{focus: %Focus{} = focus} = state) do
    case Focus.current(focus) do
      :menu -> menu(state: state.menu, width: 55)
      :select_list -> select_list(state: state.select_list, width: 55)
      :table -> showcase_table(state.table)
      :form -> form(state: state.form, gap: 0)
      :tabs -> tabs(state: state.tabs, width: 55)
      :editor -> editor(state: state.editor, focused: true, width: 16, height: 1)
    end
  end

  defp showcase_table(table_state) do
    table(
      columns: [
        %{id: :name, label: "Name", width: 12},
        %{id: :status, label: "Status", width: 10},
        %{id: :count, label: "#", width: 3, align: :right}
      ],
      state: table_state,
      width: 55
    )
  end

  defp menu_state do
    MenuState.new([
      {:section, "Actions"},
      %{id: :open, label: "Open", shortcut: "Enter", description: "Open item"},
      %{id: :rename, label: "Rename", shortcut: "r", description: "Rename item"},
      :separator,
      %{id: :delete, label: "Delete", shortcut: "d", disabled?: true}
    ])
  end

  defp select_state do
    SelectListState.new(
      [
        %{id: :dashboard, label: "Dashboard", description: "Overview and live status"},
        %{id: :sessions, label: "Sessions", description: "Recent terminal sessions"},
        %{id: :settings, label: "Settings", description: "Profiles and keybindings"}
      ],
      selected: 1,
      max_visible: 3
    )
  end

  defp table_state do
    TableState.new(
      [
        %{name: "Runtime", status: "running", count: 1},
        %{name: "Widgets", status: "ready", count: 10},
        %{name: "Overlays", status: "ready", count: 2}
      ],
      selected: 1
    )
  end

  defp form_state do
    FormState.new([
      Field.input(:name, value: "Cringe", width: 24),
      Field.editor(:notes, value: "Generic TUI\nfor the BEAM", width: 24, height: 2),
      Field.select(:theme, ["Light", "Dark", "System"], selected: 1)
    ])
  end

  defp tabs_state do
    TabsState.new(
      [
        %{id: :docs, label: "Docs", content: "Documents -> Layout -> Draw -> Frame"},
        %{id: :runtime, label: "Runtime", content: "OTP runtime with semantic events"},
        %{id: :test, label: "Tests", content: "Driver and assertions for deterministic tests"}
      ],
      selected: 0
    )
  end

  defp dialog_state do
    DialogState.new([%{id: :cancel, label: "Cancel"}, %{id: :ok, label: "OK"}], selected: 1)
  end

  defp dialog_document(dialog) do
    Dialog.render(dialog,
      title: "Overlay",
      body: "Enter selects; Escape cancels. This is document-level composition.",
      width: 38
    )
  end
end

if System.get_env("CRINGE_SHOWCASE_PREVIEW") == "1" do
  {:ok, state} = InteractiveShowcase.init([])

  state
  |> InteractiveShowcase.render()
  |> Cringe.render(width: 80, height: 24, ansi: false)
  |> IO.puts()
else
  {:ok, app} =
    Cringe.run(InteractiveShowcase,
      backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true, takeover: true},
      ansi: true,
      width: 80,
      height: 24
    )

  ref = Process.monitor(app)
  Cringe.Runtime.paint(app)

  receive do
    {:DOWN, ^ref, :process, ^app, _reason} -> :ok
  end
end
