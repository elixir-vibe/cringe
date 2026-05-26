defmodule Cringe.Runtime.Backend.Terminal do
  @moduledoc """
  Terminal backend backed by `Ghostty.TTY`.

  This backend manages terminal presentation concerns around a render stream:
  alternate screen entry, cursor visibility, initial clearing, output writes,
  and optional raw keyboard input through `Ghostty.TTY`.
  """

  @behaviour Cringe.Runtime.Backend

  @type state :: %{
          device: IO.device(),
          tty: GenServer.server() | nil,
          alternate_screen?: boolean(),
          hide_cursor?: boolean()
        }

  @impl true
  def init(opts) do
    device = Keyword.get(opts, :device, :stdio)

    with {:ok, tty} <- maybe_start_tty(opts, device) do
      state = %{
        device: device,
        tty: tty,
        alternate_screen?: Keyword.get(opts, :alternate_screen, false),
        hide_cursor?: Keyword.get(opts, :hide_cursor, true)
      }

      write(state, startup_sequence(state))
      {:ok, state}
    end
  end

  @impl true
  def render(output, state) do
    write(state, output)
    {:ok, state}
  end

  @impl true
  def stop(state) do
    write(state, shutdown_sequence(state))
    stop_tty(state.tty)
    :ok
  end

  defp maybe_start_tty(opts, device) do
    input? = Keyword.get(opts, :input, device == :stdio)

    if input? do
      opts
      |> Keyword.take([:backend, :disable_otp_reader, :raw, :takeover])
      |> Keyword.put_new(:owner, self())
      |> Ghostty.TTY.start_link()
    else
      {:ok, nil}
    end
  end

  defp write(%{tty: nil, device: device}, output), do: IO.write(device, output)
  defp write(%{tty: tty}, output), do: Ghostty.TTY.write(tty, output)

  defp stop_tty(nil), do: :ok
  defp stop_tty(tty), do: GenServer.stop(tty)

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
