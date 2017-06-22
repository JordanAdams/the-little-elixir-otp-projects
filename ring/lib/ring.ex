defmodule Ring do
  def create_processes(n),
    do: Enum.map(1..n, fn _ -> create_process() end)

  def link_processes(processes),
    do: link_processes(processes, [])

  def link_processes([p1, p2 | rest], linked) do
    IO.inspect "Linking #{inspect p1} to #{inspect p2}"
    send(p1, {:link, p2})
    link_processes([p2 | rest], [p1 | linked])
  end

  def link_processes([p1 | []], linked) do
    p2 = List.last(linked)
    IO.inspect "Linking #{inspect p1} to #{inspect p2}"
    send(p1, {:link, p2})
    :ok
  end

  defp loop do
    receive do
      {:link, pid} when is_pid(pid) ->
        Process.link(pid)
        loop()
      :crash ->
        1/0
    end
  end

  defp create_process(),
    do: spawn(&loop/0)
end
