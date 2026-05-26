defmodule Cringe.Widgets.Input do
  @moduledoc """
  Render-only text input widget and explicit input update helpers.
  """

  alias Cringe.Event.Key
  alias Cringe.Event.Text
  alias Cringe.Measure

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    opts = Cringe.Theme.input(opts)
    value = Keyword.get(opts, :value, "")
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
      |> maybe_put(:cursor, cursor(focused?, prompt, value))

    Cringe.text(prompt <> visible_value, Keyword.put(text_opts, :width, width))
  end

  @spec update(String.t(), Cringe.Event.t()) :: {:ok, String.t()} | :ignored
  def update(value, %Text{text: text}) when is_binary(value), do: {:ok, value <> text}
  def update(value, %Key{key: :backspace}) when is_binary(value), do: {:ok, trim_last(value)}
  def update(_value, _event), do: :ignored

  defp cursor(false, _prompt, _value), do: nil

  defp cursor(true, prompt, value) do
    {1, Measure.width(prompt <> value) + 1}
  end

  defp trim_last(""), do: ""

  defp trim_last(value) do
    value
    |> String.graphemes()
    |> Enum.drop(-1)
    |> Enum.join()
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
