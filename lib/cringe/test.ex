defmodule Cringe.Test do
  @moduledoc """
  Test helpers for Cringe apps and documents.
  """

  import ExUnit.Assertions

  @spec start(module(), keyword()) :: GenServer.on_start()
  def start(app, opts \\ []) do
    Cringe.Runtime.start_link(Keyword.put(opts, :app, app))
  end

  @spec event(GenServer.server(), term()) :: :ok
  def event(server, event), do: Cringe.Runtime.dispatch(server, event)

  @spec key(GenServer.server(), atom()) :: :ok
  def key(server, key), do: event(server, {:key, key})

  @spec app_text(GenServer.server()) :: String.t()
  def app_text(server), do: Cringe.Runtime.text(server)

  @spec rendered(Cringe.Document.t(), keyword()) :: String.t()
  def rendered(document, opts \\ []), do: Cringe.render(document, opts)

  @spec clean_snapshot(String.t()) :: String.t()
  def clean_snapshot(snapshot) do
    snapshot
    |> String.trim("\n")
    |> String.split("\n", trim: false)
    |> dedent_lines()
    |> Enum.join("\n")
  end

  defmacro assert_render(document, expected, opts \\ []) do
    quote do
      assert Cringe.render(unquote(document), unquote(opts)) ==
               Cringe.Test.clean_snapshot(unquote(expected))
    end
  end

  defmacro assert_text(server, expected) do
    quote do
      assert Cringe.Runtime.text(unquote(server)) == Cringe.Test.clean_snapshot(unquote(expected))
    end
  end

  defp dedent_lines(lines) do
    indent = common_indent(lines)
    Enum.map(lines, &drop_indent(&1, indent))
  end

  defp common_indent(lines) do
    lines
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&leading_spaces/1)
    |> Enum.min(fn -> 0 end)
  end

  defp leading_spaces(line) do
    line
    |> String.graphemes()
    |> Enum.take_while(&(&1 == " "))
    |> length()
  end

  defp drop_indent(line, 0), do: line

  defp drop_indent(line, indent),
    do: String.replace_prefix(line, String.duplicate(" ", indent), "")
end
