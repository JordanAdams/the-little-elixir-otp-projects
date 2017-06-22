defmodule Soupervisor do
  use GenServer

  # API

  def start_link(children, opts \\ []),
    do: GenServer.start_link(__MODULE__, children, opts)

  def start_child(supervisor, child),
    do: GenServer.call(supervisor, {:start_child, child})

  def terminate_child(supervisor, pid) when is_pid(pid),
    do: GenServer.call(supervisor, {:terminate_child, pid})

  def restart_child(supervisor, pid) when is_pid(pid),
    do: GenServer.call(supervisor, {:restart_child, pid})

  def delete_child(supervisor, pid) when is_pid(pid),
    do: GenServer.call(supervisor, {:delete_child, pid})

  def which_children(supervisor),
    do: GenServer.call(supervisor, :which_children)

  def count_children(supervisor),
    do: GenServer.call(supervisor, :count_children)

  # Callbacks

  def init(children) do
    Process.flag(:trap_exit, true)
    case start_children(children) do
      started when is_list(started) -> {:ok, Map.new(started)}
      {:error, child}               -> {:error, child}
    end
  end

  def handle_call({:start_child, child}, _from, state) do
    case do_start_child(child) do
      {:ok, pid} -> {:reply, {:ok, pid}, Map.put(state, pid, child)}
      :error     -> {:reply, :error, state}
    end
  end

  def handle_call({:terminate_child, pid}, _sender, state) do
    case do_terminate_child(pid) do
      :ok -> {:reply, :ok, state}
      _   -> {:reply, :error, state}
    end
  end

  def handle_call({:restart_child, pid}, _sender, state) do
    case Map.fetch(state, pid) do
      {:ok, spec} ->
        case do_restart_child(pid, spec) do
          {:ok, new_pid} ->
            new_state = state |> Map.delete(pid) |> Map.put(new_pid, spec)
            {:reply, {:ok, new_pid}, new_state}
          {:error, reason} ->
            {:reply, {:error, reason}, state}
          :error ->
            {:reply, :error, state}
        end
      :error -> {:reply, {:error, :not_found}, state}
    end
  end


  def handle_call({:delete_child, pid}, _sender, state) do
    case Map.has_key?(state, pid) do
      true ->
        case Process.alive?(pid) do
          false -> {:reply, :ok, Map.delete(state, pid)}
          true  -> {:reply, {:error, :running}, state}
        end
      false ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:which_children, _sender, state),
    do: {:reply, state, state}

  def handle_call(:count_children, _sender, state),
    do: {:reply, length(state), state}

  def handle_info({:EXIT, _pid, :killed}, state),
    do: {:noreply, state}

  def handle_info({:EXIT, _pid, :normal}, state),
    do: {:noreply, state}

  def handle_info({:EXIT, pid, _reason}, state) do
    with \
      {:ok, spec}    <- Map.fetch(state, pid),
      {:ok, new_pid} <- do_restart_child(pid, spec),
      new_state      <- state |> Map.delete(pid) |> Map.put(new_pid, spec)
    do
      {:noreply, new_state}
    else
      _ -> {:noreply, state}
    end
  end

  # Helpers

  defp start_children([child | rest]) do
    case do_start_child(child) do
      {:ok, pid} -> [{pid, child} | start_children(rest)]
      :error -> {:error, child}
    end
  end

  defp start_children([]), do: []

  defp do_start_child({mod, fun, args}) do
    case apply(mod, fun, args) do
      pid when is_pid(pid) ->
        Process.link(pid)
        {:ok, pid}
      _ -> :error
    end
  end

  defp do_terminate_child(pid) do
    Process.exit(pid, :kill)
    :ok
  end

  defp do_restart_child(pid, spec) when is_pid(pid) do
    case Process.alive?(pid) do
      false -> do_start_child(spec)
      true  -> {:error, :running}
    end
  end
end
