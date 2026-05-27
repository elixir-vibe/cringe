defmodule Cringe.Widget do
  @moduledoc """
  Shared widget conventions.

  Cringe widgets are plain modules that keep state explicit. A stateful widget
  usually exposes:

  * a struct-backed `State` module for app-owned state
  * `new/1` to build a renderable document from options or state
  * `render/2` as a state-first wrapper around `new/1`
  * `update/2` for default keyboard behavior
  * `update/3` when custom `Cringe.Keymap` bindings are supported

  Stateful updates return compact tuples:

  * `{:ok, state}` when widget state changed
  * `{:select, item, state}` when the user accepted a selected item/action
  * `{:cancel, state}` when the user cancelled the widget
  * `:ignored` when the widget did not handle the event

  Apps decide what those results mean. Cringe does not impose submission,
  validation, history, or product-specific command semantics.
  """

  @type update_result(state, selected) ::
          {:ok, state}
          | {:select, selected, state}
          | {:cancel, state}
          | :ignored
end
