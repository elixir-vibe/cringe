defmodule Cringe.Runtime.Backend.Terminal do
  @moduledoc """
  Terminal backend backed by `Ghostty.TTY`.

  This backend manages terminal presentation concerns around a render stream:
  alternate screen entry, cursor visibility, initial clearing, output writes,
  and optional raw keyboard input through an internal terminal session.
  """

  @behaviour Cringe.Runtime.Backend

  alias Cringe.Runtime.TerminalSession

  @type state :: %{
          device: IO.device(),
          terminal_session: GenServer.server() | nil,
          terminal_session_module: module(),
          alternate_screen?: boolean(),
          hide_cursor?: boolean()
        }

  @impl true
  def init(opts) do
    device = Keyword.get(opts, :device, :stdio)
    terminal_session = Keyword.get(opts, :terminal_session)

    state = %{
      device: device,
      terminal_session: terminal_session,
      terminal_session_module: Keyword.get(opts, :terminal_session_module, TerminalSession),
      alternate_screen?: Keyword.get(opts, :alternate_screen, false),
      hide_cursor?: Keyword.get(opts, :hide_cursor, true)
    }

    write(state, startup_sequence(state))
    {:ok, state}
  end

  @impl true
  def render(output, state) do
    write(state, output)
    {:ok, state}
  end

  @impl true
  def stop(state) do
    write(state, shutdown_sequence(state))
    :ok
  end

  defp write(%{terminal_session: nil, device: device}, output), do: IO.write(device, output)

  defp write(%{terminal_session: terminal_session, terminal_session_module: module}, output),
    do: module.write(terminal_session, output)

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
