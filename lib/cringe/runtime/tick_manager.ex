defmodule Cringe.Runtime.TickManager do
  @moduledoc false

  use GenServer

  @type interval :: pos_integer()

  @spec start_link(pid(), keyword(interval())) :: GenServer.on_start()
  def start_link(target, ticks) when is_pid(target) and is_list(ticks) do
    GenServer.start_link(__MODULE__, {target, ticks})
  end

  @impl GenServer
  def init({target, ticks}) do
    intervals = Map.new(ticks)
    Enum.each(intervals, fn {id, interval} -> schedule(id, interval) end)
    {:ok, %{target: target, intervals: intervals}}
  end

  @impl GenServer
  def handle_info({:tick, id}, %{target: target, intervals: intervals} = state) do
    if interval = intervals[id] do
      send(target, {:tick, id})
      schedule(id, interval)
    end

    {:noreply, state}
  end

  defp schedule(id, interval), do: Process.send_after(self(), {:tick, id}, interval)
end
