defmodule Cringe.DSL do
  @moduledoc """
  Block-oriented document DSL.
  """

  alias Cringe.Document.{Box, Stack}

  defmacro column(first \\ [], second \\ []), do: column_ast(first, second)
  defmacro row(first \\ [], second \\ []), do: row_ast(first, second)
  defmacro box(first \\ [], second \\ []), do: box_ast(first, second)

  def column_ast(first, second) do
    {children, opts} = children_and_opts(first, second)

    quote do
      Stack.new(unquote(children), :vertical, unquote(opts))
    end
  end

  def row_ast(first, second) do
    {children, opts} = children_and_opts(first, second)

    quote do
      Stack.new(unquote(children), :horizontal, unquote(opts))
    end
  end

  def box_ast(first, second) do
    {child, opts} = child_and_opts(first, second)

    quote do
      Box.new(unquote(child), unquote(opts))
    end
  end

  defp children_and_opts(first, second) do
    cond do
      do_block?(first) ->
        {block_children(Keyword.fetch!(first, :do)), []}

      do_block?(second) ->
        {block_children(Keyword.fetch!(second, :do)), first}

      true ->
        {first, second}
    end
  end

  defp child_and_opts(first, second) do
    cond do
      do_block?(first) ->
        {block_child(Keyword.fetch!(first, :do)), []}

      do_block?(second) ->
        {block_child(Keyword.fetch!(second, :do)), first}

      true ->
        {first, second}
    end
  end

  defp do_block?(value), do: is_list(value) and Keyword.has_key?(value, :do)

  defp block_children({:__block__, _meta, children}), do: children
  defp block_children(child), do: [child]

  defp block_child({:__block__, _meta, children}) do
    quote do
      Cringe.column(unquote(children))
    end
  end

  defp block_child(child), do: child
end
