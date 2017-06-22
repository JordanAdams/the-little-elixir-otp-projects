defmodule Cache do
  use GenServer

  def start_link(opts \\ [name: __MODULE__]),
    do: GenServer.start_link(__MODULE__, :ok, opts)

  def write(key, value),
    do: GenServer.cast(__MODULE__, {:write, key, value})

  def read(key),
    do: GenServer.call(__MODULE__, {:read, key})

  def read_all(),
    do: GenServer.call(__MODULE__, :read_all)

  def delete(key),
    do: GenServer.cast(__MODULE__, {:delete, key})

  def clear(),
    do: GenServer.cast(__MODULE__, :clear)

  def exists?(key),
    do: GenServer.call(__MODULE__, {:exists, key})


  def init(:ok),
    do: {:ok, %{}}

  def handle_call({:read, key}, _sender, state) do
    case Map.fetch(state, key) do
      {:ok, value} -> {:reply, value, state}
      _            -> {:reply, :missing, state}
    end
  end

  def handle_call(:read_all, _sender, state),
    do: {:reply, state, state}

  def handle_call({:exists, key}, _sender, state),
    do: {:reply, Map.has_key?(state, key), state}

  def handle_cast({:write, key, value}, state),
    do: {:noreply, Map.put(state, key, value)}

  def handle_cast({:delete, key}, state),
    do: {:noreply, Map.delete(state, key)}

  def handle_cast(:clear, _state),
    do: {:noreply, %{}}
end
