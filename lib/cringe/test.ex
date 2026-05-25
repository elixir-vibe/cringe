defmodule Cringe.Test do
  @moduledoc """
  Test helpers for Cringe apps.
  """

  @spec start(module(), keyword()) :: GenServer.on_start()
  def start(app, opts \\ []) do
    Cringe.Runtime.start_link(Keyword.put(opts, :app, app))
  end

  @spec event(GenServer.server(), term()) :: :ok
  def event(server, event), do: Cringe.Runtime.dispatch(server, event)

  @spec key(GenServer.server(), atom()) :: :ok
  def key(server, key), do: event(server, {:key, key})

  @spec text(GenServer.server()) :: String.t()
  def text(server), do: Cringe.Runtime.text(server)
end
