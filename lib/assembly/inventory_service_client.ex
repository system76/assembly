defmodule Assembly.InventoryServiceClient do
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
    Logger.debug("Assembly.InventoryServiceClient connecting to gateway at #{inventory_service_url()}")

    case GRPC.Stub.connect(inventory_service_url(), inventory_service_options()) do
      {:error, error} ->
        Logger.error("Assembly.InventoryServiceClient could not connect: #{error}")
        Process.sleep(5000)
        init(%{})

      channel ->
        Logger.debug("Assembly.InventoryServiceClient connected")
        {:ok, channel}
    end
  end

  @impl true
  def handle_info({:gun_down, _, _, _, _}, _state) do
    Logger.debug("Assembly.InventoryServiceClient disconnected")
    init(%{})
  end

  @impl true
  def handle_info({:gun_up, _, _, _, _}, _state) do
    Logger.debug("Assembly.InventoryServiceClient connected")
    init(%{})
  end

  @impl true
  def handle_call(:channel, _from, channel) do
    {:reply, channel, channel}
  end

  defp inventory_service_url, do: Application.get_env(:assembly, :inventory_service_url)

  defp inventory_service_options do
    if not is_nil(inventory_service_url()) and String.contains?(inventory_service_url(), "localhost") do
      [interceptors: [GRPC.Logger.Client]]
    else
      [cred: GRPC.Credential.new([]), interceptors: [GRPC.Logger.Client]]
    end
  end
end
