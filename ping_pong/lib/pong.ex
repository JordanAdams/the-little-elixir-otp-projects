defmodule PingPong.Pong do
  def loop do
    receive do
      {sender, :ping} ->
        send(sender, {self(), :pong})
        IO.puts "#{inspect(self())} <--- :ping <--- #{inspect(sender)}"
        IO.puts "#{inspect(self())} ---> :pong ---> #{inspect(sender)}"
        loop()
      _ ->
        loop()
    end
  end
end
