defmodule Cringe.Runtime.Supervisor do
  @moduledoc """
  Supervisor for a Cringe runtime process and its runtime-owned children.
  """

  use Supervisor

  @spec start_link([Cringe.Runtime.start_opt()]) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @spec runtime(Supervisor.supervisor()) :: pid() | nil
  def runtime(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {Cringe.Runtime, pid, :worker, [Cringe.Runtime]} when is_pid(pid) -> pid
      _child -> nil
    end)
  end

  @spec child_supervisor(Supervisor.supervisor()) :: pid() | nil
  def child_supervisor(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {{Cringe.Runtime.Supervisor.Children, _ref}, pid, :supervisor, [DynamicSupervisor]}
      when is_pid(pid) ->
        pid

      _child ->
        nil
    end)
  end

  @impl Supervisor
  def init(opts) do
    child_supervisor_name = {:global, {__MODULE__.Children, make_ref()}}

    children = [
      {DynamicSupervisor,
       id: Cringe.Runtime.Children, strategy: :one_for_one, name: child_supervisor_name},
      {Cringe.Runtime, Keyword.put(opts, :child_supervisor, child_supervisor_name)}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
