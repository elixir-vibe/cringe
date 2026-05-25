defmodule Cringe.Runtime.Backend.Terminal do
  @moduledoc """
  Write-only terminal backend.

  This backend manages terminal presentation concerns around a render stream:
  alternate screen entry, cursor visibility, and initial clearing. It does not
  put the terminal into raw mode or decode input yet.
  """

  @behaviour Cringe.Runtime.Backend

  @type state :: %{
          device: IO.device(),
          alternate_screen?: boolean(),
          hide_cursor?: boolean()
        }

  @impl true
  def init(opts) do
    state = %{
      device: Keyword.get(opts, :device, :stdio),
      alternate_screen?: Keyword.get(opts, :alternate_screen, false),
      hide_cursor?: Keyword.get(opts, :hide_cursor, true)
    }

    IO.write(state.device, startup_sequence(state))
    {:ok, state}
  end

  @impl true
  def render(output, %{device: device} = state) do
    IO.write(device, output)
    {:ok, state}
  end

  @impl true
  def stop(state) do
    IO.write(state.device, shutdown_sequence(state))
    :ok
  end

  defp startup_sequence(state) do
    [
      if(state.alternate_screen?, do: "\e[?1049h", else: ""),
      if(state.hide_cursor?, do: "\e[?25l", else: ""),
      "\e[H\e[2J"
    ]
  end

  defp shutdown_sequence(state) do
    [
      if(state.hide_cursor?, do: "\e[?25h", else: ""),
      if(state.alternate_screen?, do: "\e[?1049l", else: "")
    ]
  end
end
