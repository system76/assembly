defmodule Assembly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Assembly.InventoryPubSub},

      {Assembly.Broadway, []},
      {Assembly.InventoryRepo, []},
      {Assembly.Repo, []},

      {Assembly.Inventory, name: Assembly.Inventory}
    ]

    Logger.info("Starting Assembly")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Assembly.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
