defmodule Metex do
  alias Metex.{Coordinator, Worker}

  def temperatures_of(cities) do
    coordinator = spawn(Coordinator, :start, [length(cities)])

    for city <- cities, do: spawn_city_worker(city, coordinator)
  end

  defp spawn_city_worker(city, coordinator) do
    worker = spawn(Worker, :loop, [])
    send(worker, {coordinator, city})
  end
end
