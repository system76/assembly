defmodule Assembly.InventoryServiceClient do
  @moduledoc """
  A basic GenServer responsible for keeping the HTTPS gRPC connection to the
  inventory microservice alive.
  """

  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def channel() do
    GenServer.call(__MODULE__, :channel)
  end

  @impl true
  def init(_) do
    Logger.debug("Assembly.InventoryServiceClient initializing, connecting to gateway at #{config(:url)}")

    case GRPC.Stub.connect(config(:url), inventory_service_options()) do
      {:ok, channel} ->
        Logger.info("Assembly.InventoryServiceClient initialized")
        {:ok, channel}

      {:error, error} ->
        Logger.error("Assembly.InventoryServiceClient could not connect: #{error}")
        Process.sleep(5000)
        init(%{})
    end
  end

  @impl true
  def handle_info(t, state) when is_tuple(t) and elem(t, 0) == :gun_down do
    Logger.error("Assembly.InventoryServiceClient disconnected via gun, attempting to reconnect...")

    case init(%{}) do
      {:ok, channel} ->
        Logger.info("Assembly.InventoryServiceClient reconnected")
        {:noreply, channel}
    end
  end

  @impl true
  def handle_info(t, state) when is_tuple(t) and elem(t, 0) == :gun_up do
    Logger.debug("Assembly.InventoryServiceClient connected via gun")
    {:noreply, state}
  end

  @impl true
  def handle_call(:channel, _from, channel) do
    {:reply, channel, channel}
  end

  defp inventory_service_options() do
    options = [
      interceptors: [GRPC.Logger.Client]
    ]

    if config(:ssl, true) do
      Keyword.put(options, :cred, GRPC.Credential.new([]))
    else
      options
    end
  end

  defp config(key, default \\ nil) do
    config = Application.get_env(:assembly, __MODULE__)
    Keyword.get(config, key, default)
  end
end
