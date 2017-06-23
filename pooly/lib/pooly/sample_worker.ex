defmodule Pooly.SampleWorker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def stop(worker) do
    GenServer.call(worker, :stop)
  end

  def handle_call(:stop, _sender, state) do
    {:stop, :normal, :ok, state}
  end
end
