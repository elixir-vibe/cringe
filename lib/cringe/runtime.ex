defmodule Cringe.Runtime do
  @moduledoc """
  Supervised runtime for Cringe apps.
  """

  use GenServer

  alias Cringe.Event
  alias Cringe.Terminal.KeyDecoder

  @default_width 80
  @default_height 24

  @type start_opt ::
          {:app, module()}
          | {:opts, keyword()}
          | {:name, GenServer.name()}
          | {:backend, module() | {module(), keyword()}}
          | {:ticks, keyword(pos_integer())}
          | Cringe.Renderer.render_opts()

  @spec start_link([start_opt()]) :: GenServer.on_start()
  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @spec dispatch(GenServer.server(), Cringe.Event.t()) :: :ok
  def dispatch(server, event), do: GenServer.call(server, {:dispatch, event})

  @spec text(GenServer.server()) :: String.t()
  def text(server), do: GenServer.call(server, :text)

  @spec paint(GenServer.server()) :: :ok | {:error, term()}
  def paint(server), do: GenServer.call(server, :paint)

  @spec input(GenServer.server(), binary()) :: :ok | {:error, term()}
  def input(server, bytes) when is_binary(bytes) do
    Enum.each(KeyDecoder.decode(bytes), &dispatch(server, &1))
    paint(server)
  end

  @spec state(GenServer.server()) :: term()
  def state(server), do: GenServer.call(server, :state)

  @spec backend_state(GenServer.server()) :: term()
  def backend_state(server), do: GenServer.call(server, :backend_state)

  @impl GenServer
  def init(opts) do
    app = Keyword.fetch!(opts, :app)
    app_opts = Keyword.get(opts, :opts, [])
    {backend, backend_opts} = opts |> Keyword.get(:backend, {nil, []}) |> normalize_backend()
    ticks = Keyword.get(opts, :ticks, [])
    text_opts = Keyword.drop(opts, [:app, :opts, :backend, :ticks])
    render_opts = default_render_opts(text_opts)

    with {:ok, app_state} <- app.init(app_opts),
         {:ok, backend_state} <- init_backend(backend, backend_opts) do
      {:ok,
       %{
         app: app,
         app_state: app_state,
         render_opts: render_opts,
         text_opts: text_opts,
         backend: backend,
         backend_state: backend_state,
         painter: new_painter(render_opts),
         ticks: start_ticks(ticks)
       }}
    else
      {:stop, reason} -> {:stop, reason}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:dispatch, event}, _from, state) do
    case dispatch_event(state, event) do
      {:ok, next_state} -> {:reply, :ok, next_state}
      {:stop, reason} -> {:stop, reason, :ok, state}
    end
  end

  def handle_call(:text, _from, state), do: {:reply, render_text(state), state}
  def handle_call(:paint, _from, %{backend: nil} = state), do: {:reply, :ok, state}

  def handle_call(:paint, _from, %{backend: backend, backend_state: backend_state} = state) do
    {output, next_painter} = paint_output(state)
    next_state = %{state | painter: next_painter}

    if output == [] do
      {:reply, :ok, next_state}
    else
      case backend.render(output, backend_state) do
        {:ok, next_backend_state} ->
          {:reply, :ok, %{next_state | backend_state: next_backend_state}}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end
  end

  def handle_call(:state, _from, %{app_state: app_state} = state), do: {:reply, app_state, state}

  def handle_call(:backend_state, _from, %{backend_state: backend_state} = state),
    do: {:reply, backend_state, state}

  @impl GenServer
  def handle_info({Ghostty.TTY, _tty, {:key, event}}, state) do
    event
    |> KeyDecoder.from_ghostty()
    |> handle_terminal_event(state)
  end

  def handle_info({Ghostty.TTY, _tty, {:data, data}}, state) do
    handle_terminal_events(KeyDecoder.decode(data), state)
  end

  def handle_info({Ghostty.TTY, _tty, {:resize, width, height}}, state) do
    state
    |> resize(width, height)
    |> then(&handle_terminal_event(Event.resize(width, height), &1))
  end

  def handle_info({Ghostty.TTY, _tty, :eof}, state), do: {:stop, :normal, state}

  def handle_info({:tick, id}, %{ticks: ticks} = state) do
    state = schedule_tick(state, id, Map.fetch!(ticks, id))
    handle_terminal_event(Event.tick(id), state)
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl GenServer
  def terminate(_reason, %{backend: nil}), do: :ok

  def terminate(_reason, %{backend: backend, backend_state: backend_state}),
    do: backend.stop(backend_state)

  defp normalize_backend({backend, opts}) when is_atom(backend) and is_list(opts),
    do: {backend, opts}

  defp normalize_backend(backend) when is_atom(backend), do: {backend, []}

  defp init_backend(nil, _opts), do: {:ok, nil}
  defp init_backend(backend, opts), do: backend.init(opts)

  defp start_ticks(ticks) do
    ticks
    |> Map.new()
    |> tap(fn intervals ->
      Enum.each(intervals, fn {id, interval} -> send_tick(id, interval) end)
    end)
  end

  defp schedule_tick(%{ticks: ticks} = state, id, interval) do
    if Map.has_key?(ticks, id), do: send_tick(id, interval)
    state
  end

  defp send_tick(id, interval), do: Process.send_after(self(), {:tick, id}, interval)

  defp dispatch_event(%{app: app, app_state: app_state} = state, event) do
    case app.handle_event(event, app_state) do
      {:noreply, next_app_state} -> {:ok, %{state | app_state: next_app_state}}
      {:stop, reason} -> {:stop, reason}
    end
  end

  defp handle_terminal_event(:ignore, state), do: {:noreply, state}

  defp handle_terminal_event(event, state) do
    case dispatch_event(state, event) do
      {:ok, next_state} -> {:noreply, paint_after_input(next_state)}
      {:stop, reason} -> {:stop, reason, state}
    end
  end

  defp handle_terminal_events(events, state) do
    Enum.reduce_while(events, {:ok, state}, fn event, {:ok, current_state} ->
      case dispatch_event(current_state, event) do
        {:ok, next_state} -> {:cont, {:ok, next_state}}
        {:stop, reason} -> {:halt, {:stop, reason}}
      end
    end)
    |> case do
      {:ok, next_state} -> {:noreply, paint_after_input(next_state)}
      {:stop, reason} -> {:stop, reason, state}
    end
  end

  defp resize(state, width, height) do
    render_opts = state.render_opts |> Keyword.put(:width, width) |> Keyword.put(:height, height)
    %{state | render_opts: render_opts, painter: new_painter(render_opts)}
  end

  defp paint_after_input(%{backend: nil} = state), do: state

  defp paint_after_input(%{backend: backend, backend_state: backend_state} = state) do
    {output, next_painter} = paint_output(state)
    next_state = %{state | painter: next_painter}

    if output == [] do
      next_state
    else
      case backend.render(output, backend_state) do
        {:ok, next_backend_state} -> %{next_state | backend_state: next_backend_state}
        {:error, _reason} -> state
      end
    end
  end

  defp default_render_opts(opts) do
    opts
    |> Keyword.put_new(:width, @default_width)
    |> Keyword.put_new(:height, @default_height)
  end

  defp new_painter(opts) do
    Cringe.Painter.new(Keyword.fetch!(opts, :width), Keyword.fetch!(opts, :height))
  end

  defp render_text(%{app: app, app_state: app_state, text_opts: text_opts}) do
    app_state |> app.render() |> Cringe.render(text_opts)
  end

  defp paint_output(%{app: app, app_state: app_state, render_opts: render_opts, painter: painter}) do
    frame = app_state |> app.render() |> Cringe.frame(render_opts)
    Cringe.Painter.render(painter, frame)
  end
end
