defmodule Assembly.Events do
  @moduledoc """
  Encapsulate sending messages over RPC and Rabbit
  """

  require Logger

  alias Assembly.{ComponentCache, Caster}
  alias Bottle.Assembly.V1.{BuildUpdated, ComponentDemandUpdated}

  @callback broadcast_build_update(map(), map()) :: :ok
  @callback broadcast_component_demand(String.t(), integer()) :: :ok
  @callback request_quantity_update(list()) :: :ok

  @source "assembly"

  def broadcast_build_update(old, new) do
    message = BuildUpdated.new(old: Caster.cast(old), new: Caster.cast(new))
    Bottle.publish(message, source: @source)
  end

  def broadcast_component_demand(component_id, demand) do
    message = ComponentDemandUpdated.new(component_id: component_id, quantity: demand)
    Bottle.publish(message, source: @source)
  end

  def request_quantity_update(component_ids \\ []) do
    component_ids
    |> Assembly.InventoryService.request_quantity_update()
    |> Stream.each(fn {:ok, resp} ->
      ComponentCache.put(resp.component.id, resp.total_available_quantity)
    end)
    |> Stream.run()

    :ok
  end
end
