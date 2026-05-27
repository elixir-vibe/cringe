defmodule Cringe.Runtime.TerminalSession do
  @moduledoc false

  use GenServer

  @type start_opt ::
          {:backend, module()}
          | {:disable_otp_reader, boolean()}
          | {:raw, boolean()}
          | {:takeover, boolean()}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    owner = Keyword.fetch!(opts, :owner)
    terminal_opts = Keyword.get(opts, :terminal_opts, [])
    GenServer.start_link(__MODULE__, {owner, terminal_opts})
  end

  @spec start_link(pid(), [start_opt()]) :: GenServer.on_start()
  def start_link(owner, opts) when is_pid(owner) and is_list(opts) do
    start_link(owner: owner, terminal_opts: opts)
  end

  @spec write(GenServer.server(), IO.chardata()) :: :ok
  def write(session, output), do: GenServer.call(session, {:write, output})

  @impl GenServer
  def init({owner, opts}) do
    tty_opts =
      opts
      |> Keyword.take([:backend, :disable_otp_reader, :raw, :takeover])
      |> Keyword.put_new(:owner, self())

    case Ghostty.TTY.start_link(tty_opts) do
      {:ok, tty} -> {:ok, %{owner: owner, tty: tty}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:write, output}, _from, %{tty: tty} = state) do
    Ghostty.TTY.write(tty, output)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({Ghostty.TTY, _tty, _payload} = message, %{owner: owner} = state) do
    send(owner, message)
    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl GenServer
  def terminate(_reason, %{tty: tty}), do: GenServer.stop(tty)
end
