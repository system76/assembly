defmodule Assembly.Events do
  @moduledoc """
  Encapsulate resources in the message envelope and send via SQS
  """
  require Logger

  alias Assembly.Cache
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityListRequest, Stub}

  @callback request_quantity_update() :: :ok
  @callback request_quantity_update(list(integer())) :: :ok

  def request_quantity_update(component_ids \\ []) do
    components = Enum.map(component_ids, &Component.new(id: &1))
    request = ComponentAvailabilityListRequest.new(components: components, request_id: Bottle.RequestId.write(:queue))
    cred = GRPC.Credential.new([])

    with {:ok, channel} <- GRPC.Stub.connect(inventory_service_url(), cred: cred, interceptors: [GRPC.Logger.Client]),
         {:ok, stream} <- Stub.component_availability_list(channel, request) do
      stream
      |> Stream.each(fn {:ok, resp} -> Cache.update_quantity_available(resp.component.id, resp.available) end)
      |> Stream.run()

      :ok
    else
      {:error, reason} ->
        Logger.error(inspect(reason))
    end
  end

  defp inventory_service_url, do: Application.get_env(:assembly, :inventory_service_url)
end
