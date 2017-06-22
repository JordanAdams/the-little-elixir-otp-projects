defmodule PingPong.Ping do
  def loop do
    receive do
      {sender, :pong} ->
        send(sender, {self(), :ping})
        IO.puts "#{inspect(self())} <--- :pong <--- #{inspect(sender)}"
        IO.puts "#{inspect(self())} ---> :ping ---> #{inspect(sender)}"
        loop()
      _ ->
        loop()
    end
  end
end
