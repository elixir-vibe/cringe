defmodule Cringe do
  @moduledoc """
  OTP-native terminal UI toolkit for Elixir.

  Cringe builds terminal documents from plain Elixir data and renders them into
  terminal frames. The API is intentionally small while the package is early.
  """

  alias Cringe.Document.Text
  alias Cringe.Widgets.{Input, Progress, Select, Spinner}

  @doc """
  Builds a text node.

      iex> Cringe.text("hello")
      %Cringe.Document.Text{content: "hello", opts: []}

  """
  @spec text(IO.chardata(), keyword()) :: Text.t()
  def text(content, opts \\ []), do: Text.new(content, opts)

  defmacro __using__(_opts) do
    quote do
      import Cringe
    end
  end

  defmacro column(first \\ [], second \\ []), do: Cringe.DSL.column_ast(first, second)
  defmacro row(first \\ [], second \\ []), do: Cringe.DSL.row_ast(first, second)
  defmacro box(first \\ [], second \\ []), do: Cringe.DSL.box_ast(first, second)

  @doc """
  Builds a render-only progress bar widget.
  """
  @spec progress(keyword()) :: Cringe.Document.t()
  def progress(opts \\ []), do: Progress.new(opts)

  @doc """
  Builds a render-only spinner widget.
  """
  @spec spinner(keyword()) :: Cringe.Document.t()
  def spinner(opts \\ []), do: Spinner.new(opts)

  @doc """
  Builds a render-only text input widget.
  """
  @spec input(keyword()) :: Cringe.Document.t()
  def input(opts \\ []), do: Input.new(opts)

  @doc """
  Builds a render-only select/list widget.
  """
  @spec select(keyword()) :: Cringe.Document.t()
  def select(opts \\ []), do: Select.new(opts)

  @doc """
  Renders a terminal document to a string.

      iex> Cringe.text("hello") |> Cringe.render(width: 3)
      "hel"

  """
  @spec render(Cringe.Document.t(), Cringe.Renderer.render_opts()) :: String.t()
  def render(document, opts \\ []), do: Cringe.Renderer.render(document, opts)

  @doc """
  Renders a terminal document to a frame.
  """
  @spec frame(Cringe.Document.t(), Cringe.Renderer.render_opts()) :: Cringe.Frame.t()
  def frame(document, opts \\ []), do: Cringe.Renderer.frame(document, opts)

  @doc """
  Starts a Cringe runtime process linked to the caller.
  """
  @spec run(module(), keyword()) :: GenServer.on_start()
  def run(app, opts \\ []), do: Cringe.Runtime.start_link(Keyword.put(opts, :app, app))

  @doc """
  Starts a supervisor that owns a Cringe runtime process.
  """
  @spec run_supervised(module(), keyword()) :: Supervisor.on_start()
  def run_supervised(app, opts \\ []) do
    Cringe.Runtime.Supervisor.start_link(Keyword.put(opts, :app, app))
  end
end
