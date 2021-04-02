defmodule Assembly.Events do
  @moduledoc """
  Encapsulate sending messages over RPC and Rabbit
  """
  require Logger

  alias Assembly.{Builds, Cache, Caster}
  alias Bottle.Assembly.V1.BuildUpdated
  alias Bottle.Inventory.V1.{Component, ComponentAvailabilityListRequest, Stub}

  @callback broadcast_build_update(struct(), struct()) :: :ok
  @callback request_quantity_update() :: :ok
  @callback request_quantity_update(list(integer())) :: :ok

  def broadcast_build_update(old, new) do
    message = BuildUpdated.new(old: Caster.cast(old), new: Caster.cast(new))
    Bottle.publish(message, source: :assembly)
  end

  def request_quantity_update(component_ids \\ []) do
    components = Enum.map(component_ids, &Component.new(id: &1))
    request = ComponentAvailabilityListRequest.new(components: components, request_id: Bottle.RequestId.write(:queue))
    cred = GRPC.Credential.new([])

    with {:ok, channel} <- GRPC.Stub.connect(inventory_service_url(), cred: cred, interceptors: [GRPC.Logger.Client]),
         {:ok, stream} <- Stub.component_availability_list(channel, request) do
      stream
      |> Stream.each(fn {:ok, resp} -> Cache.update_quantity_available(resp.component.id, resp.available) end)
      |> Stream.run()

      Builds.recalculate_statues()

      :ok
    else
      {:error, reason} ->
        Logger.error(inspect(reason))
    end
  end

  defp inventory_service_url, do: Application.get_env(:assembly, :inventory_service_url)
end
