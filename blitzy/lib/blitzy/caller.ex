defmodule Blitzy.Caller do
  def start(url, opts \\ []) do
    n_workers = Keyword.get(opts, :n_workers, 10)
    worker_task = fn -> Blitzy.Worker.start(url) end

    1..n_workers
    |> Enum.map(fn _ -> Task.async(worker_task) end)
    |> Enum.map(&Task.await(&1, :infinity))
  end
end
