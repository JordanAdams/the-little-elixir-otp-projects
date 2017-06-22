defmodule Metex.Worker do
  use GenServer

  alias HTTPoison.Response

  @api_key System.get_env("OPEN_WEATHER_MAP_API_KEY")
  @api_base_url "http://api.openweathermap.org/data/2.5"

  # Client API

  def start_link(opts \\ [name: __MODULE__]),
    do: GenServer.start_link(__MODULE__, :ok, opts)

  def get_temperature(pid, location),
    do: GenServer.call(pid, {:location, location})

  def get_state(pid),
    do: GenServer.call(pid, :get_state)

  def flush_state(pid),
    do: GenServer.cast(pid, :flush_state)

  def stop(pid),
    do: GenServer.cast(pid, :stop)

  # Callbacks

  def init(:ok),
    do: {:ok, %{}}

  def handle_call({:location, location}, _sender, state) do
    case temperature_of(location) do
      {:ok, temp} ->
        {:reply, temp, update_state(state, location)}
      {:error, error} ->
        {:reply, {:error, error}, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call(:get_state, _sender, state),
    do: {:reply, state, state}

  def handle_cast(:flush_state, _state),
    do: {:noreply, %{}}

  def handle_cast(:stop, state),
    do: {:stop, :normal, state}

  def terminate(reason, _state) do
    IO.puts "Worker terminated: #{inspect(reason)}"
    :ok
  end

  # Helper Functions

  defp temperature_of(location) do
    case get_weather_data(location) do
      {:ok, weather_data} -> extract_temp_from_weather_data(weather_data)
      {:error, error} -> {:error, error}
      _ -> :error
    end
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

  defp update_state(state, location),
    do: Map.update(state, location, 0, &(&1 + 1))
end
