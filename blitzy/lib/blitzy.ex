defmodule Blitzy do
  def run(url, opts \\ []) do
    Blitzy.Caller.start(url, opts)
    |> parse_results
    |> IO.puts
  end

  defp parse_results(results) do
    {successes, failures} = Enum.partition(results, fn
      {:ok, _} -> true
      _        -> false
    end)

    total_workers   = length(results)
    total_successes = length(successes)
    total_failures  = length(failures)

    durations     = Enum.map(successes, fn {:ok, duration} -> duration end)
    average_time  = average(durations)
    longest_time  = Enum.max(durations)
    shortest_time = Enum.min(durations)

    """
    Total Workers:    #{total_workers}
    Successes:        #{total_successes}
    Failures:         #{total_failures}
    Average (msecs):  #{average_time}
    Longest (msecs):  #{longest_time}
    Shortest (msecs): #{shortest_time}
    """
  end

  def average(nums) do
    case Enum.sum(nums) do
      0   -> 0
      sum -> sum / length(nums)
    end
  end
end
