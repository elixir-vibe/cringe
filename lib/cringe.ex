defmodule Cringe do
  @moduledoc """
  OTP-native terminal UI toolkit for Elixir.

  Cringe builds terminal documents from plain Elixir data and renders them into
  terminal frames. The API is intentionally small while the package is early.
  """

  alias Cringe.Document.{Box, Stack, Text}

  @doc """
  Builds a text node.

      iex> Cringe.text("hello")
      %Cringe.Document.Text{content: "hello", opts: []}

  """
  @spec text(IO.chardata(), keyword()) :: Text.t()
  def text(content, opts \\ []), do: Text.new(content, opts)

  @doc """
  Builds a vertical stack.
  """
  @spec column([Cringe.Document.t()], keyword()) :: Stack.t()
  def column(children, opts \\ []), do: Stack.new(children, :vertical, opts)

  @doc """
  Builds a horizontal stack.
  """
  @spec row([Cringe.Document.t()], keyword()) :: Stack.t()
  def row(children, opts \\ []), do: Stack.new(children, :horizontal, opts)

  @doc """
  Builds a box around a document.
  """
  @spec box(Cringe.Document.t(), keyword()) :: Box.t()
  def box(child, opts \\ []), do: Box.new(child, opts)

  @doc """
  Renders a terminal document to a string.

      iex> Cringe.text("hello") |> Cringe.render(width: 3)
      "hel"

  """
  @spec render(Cringe.Document.t(), Cringe.Renderer.render_opts()) :: String.t()
  def render(document, opts \\ []), do: Cringe.Renderer.render(document, opts)
end
