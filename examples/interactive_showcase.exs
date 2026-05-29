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
       status: "Tab focuses panes · Enter selects · o toggles overlay · q quits"
     }}
  end

  @impl true
  def handle_event(%Cringe.Event.Key{key: :c, mods: [:ctrl]}, _state), do: {:stop, :normal}
  def handle_event(%Cringe.Event.Text{text: "q"}, _state), do: {:stop, :normal}

  def handle_event(%Cringe.Event.Text{text: "o"}, state) do
    {:noreply, toggle_dialog(state)}
  end

  def handle_event(%Cringe.Event.Key{key: :tab, mods: [:shift]}, state) do
    {:noreply, %{state | focus: Focus.previous(state.focus)}}
  end

  def handle_event(%Cringe.Event.Key{key: :tab}, state) do
    {:noreply, %{state | focus: Focus.next(state.focus)}}
  end

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
            anchor: :bottom_right,
            width: 48,
            margin: 1
          )

        Cringe.Overlay.render(document, Cringe.Overlay.new([overlay]),
          width: 100,
          height: 34,
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
      row gap: 2, width: 94 do
        left_column(state)
        right_column(state)
      end

      bottom_row(state)
      text(state.status, color: :bright_black)
    end
  end

  defp left_column(state) do
    column gap: 1 do
      box padding: 1 do
        column gap: 1 do
          text("Interactive Cringe", color: :green, bold: true)
          text("Focused pane: #{Focus.current(state.focus)}")
          progress(value: 0.72, width: 26, label: "Widget surface")
          spinner(frame: 2, label: "q quits · o overlay")
        end
      end

      pane(:menu, state) do
        text("Menu", bold: true)
        menu(state: state.menu, width: 42)
      end
    end
  end

  defp right_column(state) do
    column gap: 1 do
      pane(:select_list, state) do
        text("SelectList", bold: true)
        select_list(state: state.select_list, width: 44)
      end

      pane(:table, state) do
        text("Table", bold: true)

        table(
          columns: [
            %{id: :name, label: "Name", width: 12},
            %{id: :status, label: "Status", width: 9},
            %{id: :count, label: "#", width: 3, align: :right}
          ],
          state: state.table,
          width: 44
        )
      end
    end
  end

  defp bottom_row(state) do
    row gap: 2, width: 94 do
      pane(:form, state, grow: 1) do
        text("Form", bold: true)
        form(state: state.form, gap: 0)
      end

      pane(:tabs, state, grow: 1) do
        text("Tabs", bold: true)
        tabs(state: state.tabs, width: 42)
      end

      pane(:editor, state, grow: 1) do
        text("Editor", bold: true)

        editor(
          state: state.editor,
          focused: Focus.focused?(state.focus, :editor),
          width: 12,
          height: 1
        )
      end
    end
  end

  defp pane(id, state, opts \\ [], do: block) do
    color = if Focus.focused?(state.focus, id), do: :cyan, else: nil

    box Keyword.merge([padding: 1, border_color: color], opts) do
      column gap: 1 do
        block
      end
    end
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
      Field.input(:name, value: "Cringe", width: 22),
      Field.editor(:notes, value: "Generic TUI\nfor the BEAM", width: 22, height: 2),
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
      body: "This overlay captures dialog keys first. Enter selects; Escape cancels.",
      width: 42
    )
  end
end

{:ok, app} =
  Cringe.run(InteractiveShowcase,
    backend: {Cringe.Runtime.Backend.Terminal, alternate_screen: true},
    ansi: true,
    width: 100,
    height: 34
  )

ref = Process.monitor(app)
Cringe.Runtime.paint(app)

receive do
  {:DOWN, ^ref, :process, ^app, _reason} -> :ok
end
