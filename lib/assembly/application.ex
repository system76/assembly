defmodule Assembly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec, only: [hook: 1]

  require Logger

  def start(_type, _args) do
    children = [
      {SpandexDatadog.ApiServer, [http: HTTPoison, host: "127.0.0.1", batch_size: 2]},
      {Task.Supervisor, name: Assembly.TaskSupervisor},
      {Cachex, cache_options()},
      {DynamicSupervisor, name: Assembly.BuildSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: Assembly.BuildRegistry},
      Assembly.Repo,
      {GRPC.Server.Supervisor, {Assembly.Endpoint, 50_051}},
      {Assembly.Broadway, []}
    ]

    children =
      if Application.get_env(:assembly, Assembly.InventoryServiceClient)[:enabled?],
        do: children ++ [Assembly.InventoryServiceClient],
        else: children

    Logger.info("Starting Assembly")

    opts = [strategy: :one_for_one, name: Assembly.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      Task.Supervisor.async_nolink(Assembly.TaskSupervisor, fn ->
        :assembly
        |> Application.get_env(:warmup)
        |> apply([])
      end)

      {:ok, pid}
    end
  end

  defp cache_options do
    [
      name: Assembly.ComponentCache,
      hooks: [hook(module: Assembly.ComponentCache)],
      ttl: 7 * 24 * 60 * 60 * 1000
    ]
  end
end
