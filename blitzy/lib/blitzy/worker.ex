defmodule Blitzy.Worker do
  use Timex
  require Logger

  def start(url) do
    {timestamp, response} = Duration.measure(fn -> HTTPoison.get(url) end)
    handle_response({Duration.to_milliseconds(timestamp), response})
  end

  defp handle_response({msecs, {:ok, %HTTPoison.Response{status_code: code}}}) when code in 200..304,
    do: {:ok, msecs}

  defp handle_response({_msecs, {:error, reason}}),
    do: {:error, reason}

  defp handle_response({_msecs, _}),
    do: {:error, :unknown}
end
