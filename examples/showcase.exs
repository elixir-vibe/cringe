use Cringe

alias Cringe.Widgets.Dialog
alias Cringe.Widgets.Dialog.State, as: DialogState
alias Cringe.Widgets.Form.Field
alias Cringe.Widgets.Form.State, as: FormState
alias Cringe.Widgets.Menu.State, as: MenuState
alias Cringe.Widgets.SelectList.State, as: SelectListState
alias Cringe.Widgets.Table.State, as: TableState
alias Cringe.Widgets.Tabs.State, as: TabsState

menu_state =
  MenuState.new([
    {:section, "Actions"},
    %{id: :open, label: "Open", shortcut: "Enter", description: "Open selected item"},
    %{id: :rename, label: "Rename", shortcut: "r", description: "Rename item"},
    :separator,
    %{id: :delete, label: "Delete", shortcut: "d", disabled?: true}
  ])

select_state =
  SelectListState.new(
    [
      %{id: :dashboard, label: "Dashboard", description: "Overview and live status"},
      %{id: :sessions, label: "Sessions", description: "Recent terminal sessions"},
      %{id: :settings, label: "Settings", description: "Profiles and keybindings"}
    ],
    selected: 1,
    max_visible: 3
  )

table_state =
  TableState.new(
    [
      %{name: "Runtime", status: "running", count: 1},
      %{name: "Widgets", status: "ready", count: 10},
      %{name: "Overlays", status: "ready", count: 2}
    ],
    selected: 1
  )

form_state =
  FormState.new([
    Field.input(:name, value: "Cringe", width: 22),
    Field.editor(:notes, value: "Generic TUI\nfor the BEAM", width: 22, height: 2),
    Field.select(:theme, ["Light", "Dark", "System"], selected: 1)
  ])

tabs_state =
  TabsState.new(
    [
      %{id: :docs, label: "Docs", content: "Documents -> Layout -> Draw -> Frame"},
      %{id: :runtime, label: "Runtime", content: "OTP runtime with semantic events"},
      %{id: :test, label: "Tests", content: "Driver and assertions for deterministic tests"}
    ],
    selected: 0
  )

dialog_state =
  DialogState.new([%{id: :cancel, label: "Cancel"}, %{id: :ok, label: "OK"}], selected: 1)

left =
  column gap: 1 do
    box padding: 1 do
      column gap: 1 do
        text("Cringe", color: :green, bold: true)
        text("OTP-native terminal UI toolkit")
        progress(value: 0.72, width: 26, label: "Widget surface")
        spinner(frame: 2, label: "Semantic runtime events")
      end
    end

    box padding: 1 do
      column gap: 1 do
        text("Menu", bold: true)
        menu(state: menu_state, width: 42)
      end
    end
  end

right =
  column gap: 1 do
    box padding: 1 do
      column gap: 1 do
        text("SelectList", bold: true)
        select_list(state: select_state, width: 44)
      end
    end

    box padding: 1 do
      column gap: 1 do
        text("Table", bold: true)

        table(
          columns: [
            %{id: :name, label: "Name", width: 12},
            %{id: :status, label: "Status", width: 9},
            %{id: :count, label: "#", width: 3, align: :right}
          ],
          state: table_state,
          width: 44
        )
      end
    end
  end

bottom =
  row gap: 2, width: 94 do
    box padding: 1, grow: 1 do
      column gap: 1 do
        text("Form", bold: true)
        form(state: form_state, gap: 0)
      end
    end

    box padding: 1, grow: 1 do
      column gap: 1 do
        text("Tabs + Editor viewport", bold: true)
        tabs(state: tabs_state, width: 42)
        editor(value: "abcdef", cursor_col: 5, focused: true, width: 3, height: 1)
      end
    end
  end

base =
  column gap: 1 do
    row gap: 2, width: 94 do
      left
      right
    end

    bottom
  end

overlays =
  Cringe.Overlay.new([
    Cringe.Overlay.layer(
      :dialog,
      Dialog.render(dialog_state,
        title: "Overlay",
        body: "Pure overlays compose documents; runtime overlays can repaint immediately.",
        width: 42
      ),
      anchor: :bottom_right,
      width: 48,
      margin: 1,
      capture?: true
    )
  ])

base
|> Cringe.Overlay.render(overlays, width: 100, height: 34, ansi: true)
|> IO.puts()
