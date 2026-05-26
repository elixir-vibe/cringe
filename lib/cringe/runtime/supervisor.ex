defmodule Cringe.Runtime.Supervisor do
  @moduledoc """
  Supervisor for a Cringe runtime process.
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

  @impl Supervisor
  def init(opts) do
    Supervisor.init([{Cringe.Runtime, opts}], strategy: :one_for_one)
  end
end
