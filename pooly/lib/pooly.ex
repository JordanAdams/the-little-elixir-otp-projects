defmodule Pooly do
  use Application

  def start(_type, _args) do
    pool_config = [
      mfa: {Pooly.SampleWorker, :start_link, []},
      size: 5
    ]

    start_pool(pool_config)
  end

  def start_pool(pool_config),
    do: Pooly.Supervisor.start_link(pool_config)

  def checkout(),
    do: Pooly.Server.checkout()

  def checkin(worker),
    do: Pooly.Server.checkin(worker)

  def status(),
    do: Pooly.Server.status()
end
