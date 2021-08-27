defmodule Assembly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  import Cachex.Spec

  def start(_type, _args) do
    children =
      [
        {SpandexDatadog.ApiServer, [http: HTTPoison, host: "127.0.0.1", batch_size: 2]},
        {DynamicSupervisor, name: Assembly.BuildSupervisor, strategy: :one_for_one},
        {Registry, keys: :unique, name: Assembly.Registry},
        Assembly.Repo,
        {Cachex, cachex_opts()},
        {GRPC.Server.Supervisor, {Assembly.Endpoint, 50_051}},
        {Assembly.Broadway, []}
      ]
      |> maybe_put(Assembly.InventoryServiceClient, Application.get_env(:assembly, :inventory_service_url))

    Logger.info("Starting Assembly")

    opts = [strategy: :one_for_one, name: Assembly.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      warmup()

      {:ok, pid}
    end
  end

  defp cachex_opts do
    if opts = Application.get_env(:assembly, :cachex_opts) do
      opts
    else
      [
        name: Assembly.Cache,
        fallback: fallback(default: &Assembly.Cache.fallback/1)
      ]
    end
  end

  defp warmup do
    :assembly
    |> Application.get_env(:warmup)
    |> apply([])
  end

  defp maybe_put(list, _value, false), do: list
  defp maybe_put(list, _value, nil), do: list
  defp maybe_put(list, value, _), do: list ++ [value]
end
