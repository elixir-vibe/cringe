defmodule Cringe.Runtime.Backend.Test do
  @moduledoc """
  In-memory runtime backend for tests.
  """

  @behaviour Cringe.Runtime.Backend

  @impl true
  def init(_opts), do: {:ok, []}

  @impl true
  def render(text, frames), do: {:ok, [text | frames]}

  @impl true
  def stop(_frames), do: :ok

  @spec frames(GenServer.server()) :: [String.t()]
  def frames(server), do: Cringe.Runtime.backend_state(server) |> Enum.reverse()
end
