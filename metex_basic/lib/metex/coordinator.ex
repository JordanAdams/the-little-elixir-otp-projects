defmodule Metex.Coordinator do
  def start(expected) do
    loop(%{
      expected: expected,
      results: []
    })
  end

  def loop(state) do
    receive do
      {:ok, result} -> handle_result(result, state)
      :exit         -> handle_exit(state)
      _             -> loop(state)
    end
  end

  def handle_result(result, state = %{expected: expected, results: results}) do
    new_results = [result | results]

    if length(new_results) === expected, do: send(self(), :exit)

    loop(Map.put(state, :results, new_results))
  end

  def handle_exit(%{results: results}) do
    results
    |> Enum.sort
    |> Enum.join(", ")
    |> IO.puts
  end
end
