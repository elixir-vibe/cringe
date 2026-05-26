defmodule Cringe.Widgets.Input do
  @moduledoc """
  Render-only text input widget.
  """

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    value = Keyword.get(opts, :value, "")
    placeholder = Keyword.get(opts, :placeholder, "")
    focused? = Keyword.get(opts, :focused, false)
    width = Keyword.get(opts, :width, 20)
    prompt = Keyword.get(opts, :prompt, "> ")
    cursor = if focused?, do: "▌", else: ""
    visible_value = if value == "", do: placeholder, else: value

    color =
      if value == "",
        do: Keyword.get(opts, :placeholder_color, :bright_black),
        else: Keyword.get(opts, :color)

    text_opts =
      opts
      |> Keyword.drop([:value, :placeholder, :focused, :width, :prompt, :placeholder_color])
      |> maybe_put(:color, color)

    Cringe.text(prompt <> visible_value <> cursor, Keyword.put(text_opts, :width, width))
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
