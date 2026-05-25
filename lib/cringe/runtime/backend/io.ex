defmodule Cringe.Runtime.Backend.IO do
  @moduledoc """
  Runtime backend that writes rendered frames to an Elixir IO device.

  This backend is intentionally small: it writes exactly the rendered text it is
  given. Interactive terminal concerns such as raw mode, key decoding, cursor
  visibility, and resize events belong in a terminal backend.
  """

  @behaviour Cringe.Runtime.Backend

  @type state :: %{device: Elixir.IO.device()}

  @impl true
  def init(opts) do
    {:ok, %{device: Keyword.get(opts, :device, :stdio)}}
  end

  @impl true
  def render(text, %{device: device} = state) do
    Elixir.IO.write(device, text)
    {:ok, state}
  end

  @impl true
  def stop(_state), do: :ok
end
