defmodule Assembly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  import Cachex.Spec

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Assembly.BuildSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: Assembly.Registry},
      Assembly.Repo,
      {Cachex, cachex_opts()},
      {GRPC.Server.Supervisor, {Assembly.Endpoint, 50_051}},
      {Assembly.Broadway, []}
    ]

    Logger.info("Starting Assembly")

    opts = [strategy: :one_for_one, name: Assembly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cachex_opts do
    if opts = Application.get_env(:assembly, :cachex_opts) do
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
