defmodule Assembly.InventoryService do
  @moduledoc """
  Handles forming the request and parsing the response from the inventory
  microservice gRPC server.
  """

  require Logger

  alias Bottle.Inventory.V1.{Component, ListComponentAvailabilityRequest, Stub}
  alias Assembly.InventoryServiceClient

  @spec request_quantity_update([String.t()]) :: Enumerable.t()
  def request_quantity_update(component_ids \\ []) do
    components = Enum.map(component_ids, &Component.new(id: &1))
    request = ListComponentAvailabilityRequest.new(components: components, request_id: Bottle.RequestId.write(:queue))

    with {:ok, channel} <- InventoryServiceClient.channel(),
         {:ok, stream} <- Stub.list_component_availability(channel, request) do
      stream
    else
      {:error, reason} ->
        Logger.error("Unable to get component availability from inventory service", resource: inspect(reason))
        Stream.cycle([])
    end
  end
end
