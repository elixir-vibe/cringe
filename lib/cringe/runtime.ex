defmodule Cringe.Runtime do
  @moduledoc """
  Supervised runtime for Cringe apps.
  """

  use GenServer

  @type start_opt ::
          {:app, module()}
          | {:opts, keyword()}
          | {:name, GenServer.name()}
          | {:backend, {module(), keyword()}}
          | Cringe.Renderer.render_opts()

  @spec start_link([start_opt()]) :: GenServer.on_start()
  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @spec dispatch(GenServer.server(), term()) :: :ok
  def dispatch(server, event), do: GenServer.call(server, {:dispatch, event})

  @spec text(GenServer.server()) :: String.t()
  def text(server), do: GenServer.call(server, :text)

  @spec paint(GenServer.server()) :: :ok | {:error, term()}
  def paint(server), do: GenServer.call(server, :paint)

  @spec state(GenServer.server()) :: term()
  def state(server), do: GenServer.call(server, :state)

  @spec backend_state(GenServer.server()) :: term()
  def backend_state(server), do: GenServer.call(server, :backend_state)

  @impl GenServer
  def init(opts) do
    app = Keyword.fetch!(opts, :app)
    app_opts = Keyword.get(opts, :opts, [])
    {backend, backend_opts} = Keyword.get(opts, :backend, {nil, []})
    render_opts = Keyword.drop(opts, [:app, :opts, :backend])

    with {:ok, app_state} <- app.init(app_opts),
         {:ok, backend_state} <- init_backend(backend, backend_opts) do
      {:ok,
       %{
         app: app,
         app_state: app_state,
         render_opts: render_opts,
         backend: backend,
         backend_state: backend_state
       }}
    else
      {:stop, reason} -> {:stop, reason}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:dispatch, event}, _from, %{app: app, app_state: app_state} = state) do
    case app.handle_event(event, app_state) do
      {:noreply, next_app_state} -> {:reply, :ok, %{state | app_state: next_app_state}}
      {:stop, reason} -> {:stop, reason, :ok, state}
    end
  end

  def handle_call(:text, _from, state), do: {:reply, render_text(state), state}
  def handle_call(:paint, _from, %{backend: nil} = state), do: {:reply, :ok, state}

  def handle_call(:paint, _from, %{backend: backend, backend_state: backend_state} = state) do
    case backend.render(render_text(state), backend_state) do
      {:ok, next_backend_state} -> {:reply, :ok, %{state | backend_state: next_backend_state}}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:state, _from, %{app_state: app_state} = state), do: {:reply, app_state, state}

  def handle_call(:backend_state, _from, %{backend_state: backend_state} = state),
    do: {:reply, backend_state, state}

  @impl GenServer
  def terminate(_reason, %{backend: nil}), do: :ok

  def terminate(_reason, %{backend: backend, backend_state: backend_state}),
    do: backend.stop(backend_state)

  defp init_backend(nil, _opts), do: {:ok, nil}
  defp init_backend(backend, opts), do: backend.init(opts)

  defp render_text(%{app: app, app_state: app_state, render_opts: render_opts}) do
    app_state |> app.render() |> Cringe.render(render_opts)
  end
end
