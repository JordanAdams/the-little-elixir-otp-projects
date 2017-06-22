defmodule Werker do
  def start_link(name \\ __MODULE__),
    do: spawn(fn -> loop(name) end)

  defp loop(name) do
    receive do
      :stop -> :ok
      :crash -> 1/0
      message ->
        IO.inspect message
        loop(name)
    end
  end
end
