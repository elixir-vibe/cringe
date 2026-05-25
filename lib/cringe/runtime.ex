defmodule Cringe.Runtime do
  @moduledoc """
  Supervised runtime for Cringe apps.
  """

  use GenServer

  @type start_opt ::
          {:app, module()}
          | {:opts, keyword()}
          | {:name, GenServer.name()}
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

  @spec state(GenServer.server()) :: term()
  def state(server), do: GenServer.call(server, :state)

  @impl GenServer
  def init(opts) do
    app = Keyword.fetch!(opts, :app)
    app_opts = Keyword.get(opts, :opts, [])
    render_opts = Keyword.drop(opts, [:app, :opts])

    case app.init(app_opts) do
      {:ok, app_state} -> {:ok, %{app: app, app_state: app_state, render_opts: render_opts}}
      {:stop, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:dispatch, event}, _from, %{app: app, app_state: app_state} = state) do
    case app.handle_event(event, app_state) do
      {:noreply, next_app_state} -> {:reply, :ok, %{state | app_state: next_app_state}}
      {:stop, reason} -> {:stop, reason, :ok, state}
    end
  end

  def handle_call(
        :text,
        _from,
        %{app: app, app_state: app_state, render_opts: render_opts} = state
      ) do
    text = app_state |> app.render() |> Cringe.render(render_opts)
    {:reply, text, state}
  end

  def handle_call(:state, _from, %{app_state: app_state} = state), do: {:reply, app_state, state}
end
