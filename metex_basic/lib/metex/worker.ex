defmodule Metex.Worker do
  alias HTTPoison.Response

  @api_key System.get_env("OPEN_WEATHER_MAP_API_KEY")
  @api_base_url "http://api.openweathermap.org/data/2.5"

  def loop do
    receive do
      {pid, location} -> send(pid, {:ok, temperature_of(location)})
      _               -> IO.puts "Unknown message"
    end
    loop()
  end

  def temperature_of(location) do
    with {:ok, weather_data} <- get_weather_data(location),
         {:ok, temp}         <- extract_temp_from_weather_data(weather_data),
         do: "#{location}: #{temp}°C"
  end

  defp get_weather_data(location) do
    params = %{
      "q"     => URI.encode(location),
      "appid" => @api_key,
      "units" => "metric"
    }

    case HTTPoison.get("#{@api_base_url}/weather", [], params: params) do
      {:ok, %Response{body: body, status_code: 200}} ->
        JSON.decode(body)
      {_, reason} ->
        {:error, reason}
    end
  end

  defp extract_temp_from_weather_data(weather_data) do
    with {:ok, main} <- Map.fetch(weather_data, "main"),
         {:ok, temp} <- Map.fetch(main, "temp"),
         do: {:ok, temp}
  end
end
