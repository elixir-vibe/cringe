defmodule Cringe.Widgets.Select do
  @moduledoc """
  Render-only select/list widget and explicit selection update helpers.
  """

  alias Cringe.Document.Stack
  alias Cringe.Event.Key

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    opts = Cringe.Theme.select(opts)
    options = Keyword.get(opts, :options, [])
    selected = opts |> Keyword.get(:selected, 0) |> clamp_index(options)
    focused? = Keyword.get(opts, :focused, false)
    marker = Keyword.get(opts, :marker)
    blank = String.duplicate(" ", Cringe.Measure.width(marker))

    container_opts =
      opts
      |> Keyword.drop([:focused, :marker, :options, :selected])
      |> Keyword.put_new(:role, :select)
      |> Keyword.put_new(:focusable, true)

    options
    |> Enum.with_index()
    |> Enum.map(fn {option, index} ->
      prefix = if index == selected, do: marker, else: blank
      style = row_style(index == selected, focused?)
      Cringe.text(prefix <> " " <> to_string(option), style)
    end)
    |> Stack.new(:vertical, container_opts)
  end

  @spec update(non_neg_integer(), Cringe.Event.t(), [term()]) ::
          {:ok, non_neg_integer()} | :ignored
  def update(selected, %Key{key: key}, options) when key in [:down, :right, :j] do
    {:ok, clamp_index(selected + 1, options)}
  end

  def update(selected, %Key{key: key}, options) when key in [:up, :left, :k] do
    {:ok, clamp_index(selected - 1, options)}
  end

  def update(_selected, _event, _options), do: :ignored

  defp row_style(true, true), do: Cringe.Style.variant(:focused, [])
  defp row_style(true, false), do: Cringe.Style.variant(:selected, [])
  defp row_style(false, _focused?), do: []

  defp clamp_index(_selected, []), do: 0
  defp clamp_index(selected, options), do: selected |> max(0) |> min(length(options) - 1)
end
