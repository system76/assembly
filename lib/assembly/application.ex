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
      Assembly.Repo,
      {Cachex, cachex_opts()},
      supervisor(GRPC.Server.Supervisor, [{Assembly.Endpoint, 50051}]),
      {Assembly.Broadway, []}
    ]

    Logger.info("Starting Assembly")

    opts = [strategy: :one_for_one, name: Assembly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cachex_opts do
    if opts = Application.get_env(:assembly, :cachex_opts) do
      IO.inspect(opts)
      opts
    else
      [
        name: Assembly.Cache,
        warmers: [
          warmer(module: Assembly.Cache)
        ],
        fallback: fallback(default: &Assembly.Cache.fallback/1)
      ]
    end
  end
end
