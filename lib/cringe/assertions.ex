defmodule Cringe.Assertions do
  @moduledoc """
  ExUnit assertions for Cringe documents and apps.
  """

  import ExUnit.Assertions

  @doc """
  Normalizes an expected multiline heredoc for render assertions.

  Leading/trailing newlines are removed and common indentation is stripped, so
  expected terminal output can stay readable inside test modules.
  """
  @spec clean_heredoc(String.t()) :: String.t()
  def clean_heredoc(heredoc) do
    heredoc
    |> String.trim("\n")
    |> String.split("\n", trim: false)
    |> dedent_lines()
    |> Enum.join("\n")
  end

  defmacro assert_render(document, expected, opts \\ []) do
    quote do
      assert Cringe.render(unquote(document), unquote(opts)) ==
               Cringe.Assertions.clean_heredoc(unquote(expected))
    end
  end

  defmacro assert_app_text(app, expected) do
    quote do
      assert Cringe.Driver.text(unquote(app)) ==
               Cringe.Assertions.clean_heredoc(unquote(expected))
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
