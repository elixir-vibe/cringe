defmodule Cringe.Keymap do
  @moduledoc """
  Named keyboard bindings for widgets and apps.

  Keymaps let widgets depend on semantic actions instead of hard-coded key
  checks. Bindings are stored as `Cringe.Keymap.Binding` structs.

      iex> keymap = Cringe.Keymap.new(cancel: [:escape, {:c, [:ctrl]}])
      iex> Cringe.Keymap.match?(keymap, :cancel, Cringe.Event.key(:c, mods: [:ctrl]))
      true

      iex> Cringe.Keymap.action(keymap, Cringe.Event.key(:escape))
      {:ok, :cancel}

  """

  alias Cringe.Keymap.Binding

  defstruct actions: %{}

  @type action :: term()
  @type binding_spec :: Binding.t() | atom() | {atom(), [Cringe.Event.Key.mod()]}
  @type t :: %__MODULE__{actions: %{optional(action()) => [Binding.t()]}}

  @spec new(keyword()) :: t()
  def new(actions \\ []) when is_list(actions) do
    Enum.reduce(actions, %__MODULE__{}, fn {action, bindings}, keymap ->
      put(keymap, action, List.wrap(bindings))
    end)
  end

  @spec put(t(), action(), [binding_spec()] | binding_spec()) :: t()
  def put(%__MODULE__{} = keymap, action, bindings) do
    bindings = bindings |> List.wrap() |> Enum.map(&Binding.normalize/1)
    %{keymap | actions: Map.put(keymap.actions, action, bindings)}
  end

  @spec bindings(t(), action()) :: [Binding.t()]
  def bindings(%__MODULE__{} = keymap, action), do: Map.get(keymap.actions, action, [])

  @spec match?(t(), action(), Cringe.Event.t()) :: boolean()
  def match?(%__MODULE__{} = keymap, action, event) do
    keymap
    |> bindings(action)
    |> Enum.any?(&Binding.matches?(&1, event))
  end

  @spec action(t(), Cringe.Event.t()) :: {:ok, action()} | :error
  def action(%__MODULE__{} = keymap, event) do
    Enum.find_value(keymap.actions, :error, fn {action, bindings} ->
      if Enum.any?(bindings, &Binding.matches?(&1, event)), do: {:ok, action}
    end)
  end
end
