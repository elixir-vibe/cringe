defmodule Cringe.Driver do
  @moduledoc """
  Test driver helpers for Cringe apps.
  """

  alias Cringe.Runtime.Backend.Test, as: TestBackend

  @spec start(module(), keyword()) :: GenServer.on_start()
  def start(app, opts \\ []) do
    Cringe.Runtime.start_link(Keyword.put(opts, :app, app))
  end

  @spec event(GenServer.server(), Cringe.Event.t()) :: :ok
  def event(app, event), do: Cringe.Runtime.dispatch(app, event)

  @spec key(GenServer.server(), atom(), keyword()) :: :ok
  def key(app, key, opts \\ []), do: event(app, Cringe.Event.key(key, opts))

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
end
