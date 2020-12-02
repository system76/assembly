defmodule Assembly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  import Cachex.Spec
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      {Assembly.Broadway, []},
      # For populating the Cache we have a few options:
      # 1. We can handle this ourselves
      # 2. Investigate and possibly leverage Cachex's warming functionality
      #   https://hexdocs.pm/cachex/reactive-warming.html#content
      #   https://hexdocs.pm/cachex/proactive-warming.html#content
      {Cachex,
       [
         name: Assembly.Cache,
         warmers: [
           warmer(module: Assembly.Cache)
         ]
       ]},
      supervisor(GRPC.Server.Supervisor, [{Assembly.Endpoint, 50051}]),
      {DynamicSupervisor, name: Assembly.BuildSupervisor, strategy: :one_for_one}
    ]

    Logger.info("Starting Assembly")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Assembly.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
