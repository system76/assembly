defmodule Assembly.InventoryService do
  require Logger

  alias Bottle.Inventory.V1.{Component, ListComponentAvailabilityRequest, Stub}
  alias Assembly.InventoryServiceClient
  alias Assembly.{Builds, Cache, Caster}

  @spec request_quantity_update(Enum.t()) :: List.t() | Stream.t()
  def request_quantity_update(component_ids \\ []) do
    components = Enum.map(component_ids, &Component.new(id: &1))
    request = ListComponentAvailabilityRequest.new(components: components, request_id: Bottle.RequestId.write(:queue))

    with {:ok, channel} <- InventoryServiceClient.channel(),
         {:ok, stream} <- Stub.list_component_availability(channel, request) do
      stream
    else
      {:error, reason} ->
        Logger.error("Unable to get component availability from inventory service", resource: inspect(reason))
        []
    end
  end
end
