defmodule Cringe.Widgets.Input do
  @moduledoc """
  Render-only text input widget and explicit input update helpers.
  """

  alias Cringe.Event.Key
  alias Cringe.Event.Text
  alias Cringe.Measure
  alias Cringe.Widgets.Input.State

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    opts = Cringe.Theme.input(opts)
    state = state_from_opts(opts)
    value = state.value
    placeholder = Keyword.get(opts, :placeholder, "")
    focused? = Keyword.get(opts, :focused, false)
    width = Keyword.get(opts, :width, 20)
    prompt = Keyword.get(opts, :prompt, "> ")
    visible_value = if value == "", do: placeholder, else: value

    color =
      if value == "",
        do: Keyword.get(opts, :placeholder_color),
        else: Keyword.get(opts, :color)

    text_opts =
      opts
      |> Keyword.drop([:value, :placeholder, :focused, :width, :prompt, :placeholder_color])
      |> maybe_put(:color, color)
      |> maybe_put(:cursor, cursor(focused?, prompt, state))

    Cringe.text(prompt <> visible_value, Keyword.put(text_opts, :width, width))
  end

  @spec update(String.t() | State.t(), Cringe.Event.t()) ::
          {:ok, String.t() | State.t()} | :ignored
  def update(%State{} = state, %Text{text: text}), do: {:ok, State.insert(state, text)}
  def update(%State{} = state, %Key{key: :backspace}), do: {:ok, State.backspace(state)}
  def update(%State{} = state, %Key{key: :delete}), do: {:ok, State.delete(state)}
  def update(%State{} = state, %Key{key: :left}), do: {:ok, State.move(state, -1)}
  def update(%State{} = state, %Key{key: :right}), do: {:ok, State.move(state, 1)}
  def update(%State{} = state, %Key{key: :home}), do: {:ok, State.home(state)}
  def update(%State{} = state, %Key{key: :end}), do: {:ok, State.end_of_line(state)}

  def update(value, event) when is_binary(value) do
    case update(State.new(value), event) do
      {:ok, %State{} = state} -> {:ok, State.value(state)}
      :ignored -> :ignored
    end
  end

  def update(_value, _event), do: :ignored

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state -> state
      nil -> State.new(Keyword.get(opts, :value, ""), cursor: Keyword.get(opts, :cursor))
    end
  end

  defp cursor(false, _prompt, _state), do: nil

  defp cursor(true, prompt, %State{} = state) do
    value_before_cursor =
      state.value
      |> String.graphemes()
      |> Enum.take(state.cursor)
      |> Enum.join()

    {1, Measure.width(prompt <> value_before_cursor) + 1}
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
