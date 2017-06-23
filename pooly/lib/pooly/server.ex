defmodule Pooly.Server do
  use GenServer
  import Supervisor.Spec

  defmodule State do
    defstruct [:sup, :size, :mfa, :worker_sup, :workers, :monitors]
  end

  def start_link(sup, pool_config),
    do: GenServer.start_link(__MODULE__, {sup, pool_config}, name: __MODULE__)

  def checkout(),
    do: GenServer.call(__MODULE__, :checkout)

  def checkin(worker),
    do: GenServer.cast(__MODULE__, {:checkin, worker})

  def status(),
    do: GenServer.call(__MODULE__, :status)

  def init({sup, pool_config}) when is_pid(sup) do
    state = %State{}
    |> Map.put(:sup, sup)
    |> Map.put(:size, Keyword.get(pool_config, :size))
    |> Map.put(:mfa, Keyword.get(pool_config, :mfa))
    |> Map.put(:monitors, :ets.new(:monitors, [:set, :private]))

    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def handle_call(:checkout, consumer, state) do
    case state.workers do
      [worker | rest] ->
        ref = Process.monitor(consumer)
        :ets.insert(state.monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}
      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_call(:status, _from, state) do
    status = {length(state.workers), :ets.info(state.monitors, :size)}

    {:reply, status, state}
  end

  def handle_cast({:checkin, worker}, state) do
    case :ets.lookup(state.monitors, worker) do
      [{pid, ref}] ->
        Process.demonitor(ref)
        :ets.delete(state.monitors, pid)
        {:noreply, %{state | workers: [pid | state.workers]}}
      [] ->
        {:noreply, state}
    end
  end

  def handle_info(:start_worker_supervisor, state) do
    {:ok, worker_sup} = Supervisor.start_child(state.sup, supervisor_spec(state.mfa))

    new_state = %{state |
      worker_sup: worker_sup,
      workers: prepopulate(state.size, worker_sup)
    }

    {:noreply, new_state}
  end

  defp supervisor_spec(mfa) do
    supervisor(Pooly.WorkerSupervisor, [mfa], restart: :temporary)
  end

  defp prepopulate(size, worker_sup) do
    Enum.map(1..size, fn _ -> new_worker(worker_sup) end)
  end

  defp new_worker(worker_sup) do
    {:ok, worker} = Supervisor.start_child(worker_sup, [[]])
    worker
  end
end
