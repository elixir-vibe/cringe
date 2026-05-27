defmodule Cringe.Driver do
  @moduledoc """
  Test driver helpers for Cringe apps.
  """

  alias Cringe.Runtime.Backend.Test, as: TestBackend

  @default_attempts 20
  @default_interval 5

  @spec start(module(), keyword()) :: GenServer.on_start()
  def start(app, opts \\ []) do
    Cringe.Runtime.start_link(Keyword.put(opts, :app, app))
  end

  @spec event(GenServer.server(), Cringe.Event.t()) :: :ok
  def event(app, event), do: Cringe.Runtime.dispatch(app, event)

  @spec key(GenServer.server(), atom(), keyword()) :: :ok
  def key(app, key, opts \\ []), do: event(app, Cringe.Event.key(key, opts))

  @spec keys(GenServer.server(), [atom() | {atom(), keyword()}]) :: :ok
  def keys(app, keys) when is_list(keys) do
    Enum.each(keys, fn
      {key, opts} -> key(app, key, opts)
      key -> key(app, key)
    end)
  end

  @spec text_input(GenServer.server(), binary()) :: :ok | {:error, term()}
  def text_input(app, text) when is_binary(text), do: Cringe.Runtime.input(app, text)

  @spec paint(GenServer.server()) :: :ok | {:error, term()}
  def paint(app), do: Cringe.Runtime.paint(app)

  @spec text(GenServer.server()) :: String.t()
  def text(app), do: Cringe.Runtime.text(app)

  @spec frames(GenServer.server()) :: [String.t()]
  def frames(app), do: TestBackend.frames(app)

  @spec state(GenServer.server()) :: term()
  def state(app), do: Cringe.Runtime.state(app)

  @spec await_state(GenServer.server(), (term() -> as_boolean(term())), keyword()) :: boolean()
  def await_state(app, fun, opts \\ []) when is_function(fun, 1) do
    await(fn -> fun.(state(app)) end, opts)
  end

  @spec await_frame(GenServer.server(), (String.t() -> as_boolean(term())), keyword()) ::
          boolean()
  def await_frame(app, fun, opts \\ []) when is_function(fun, 1) do
    await(fn -> Enum.any?(frames(app), fun) end, opts)
  end

  @spec await_text(GenServer.server(), (String.t() -> as_boolean(term())), keyword()) :: boolean()
  def await_text(app, fun, opts \\ []) when is_function(fun, 1) do
    await(fn -> app |> text() |> fun.() end, opts)
  end

  defp await(fun, opts) do
    attempts = Keyword.get(opts, :attempts, @default_attempts)
    interval = Keyword.get(opts, :interval, @default_interval)
    do_await(fun, attempts, interval)
  end

  defp do_await(fun, attempts, interval) when attempts > 0 do
    if fun.() do
      true
    else
      Process.sleep(interval)
      do_await(fun, attempts - 1, interval)
    end
  end

  defp do_await(_fun, 0, _interval), do: false
end
