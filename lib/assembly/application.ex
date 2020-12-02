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
      {DynamicSupervisor, name: Assembly.BuildSupervisor, strategy: :one_for_one},
      {Cachex,
       [
         name: Assembly.Cache,
         warmers: [
           warmer(module: Assembly.Cache)
         ]
       ]},
      supervisor(GRPC.Server.Supervisor, [{Assembly.Endpoint, 50051}]),
      {Assembly.Broadway, []}
    ]

    Logger.info("Starting Assembly")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Assembly.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
