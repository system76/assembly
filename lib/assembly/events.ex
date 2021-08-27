defmodule Assembly.Events do
  @moduledoc """
  Encapsulate sending messages over RPC and Rabbit
  """
  require Logger

  alias Assembly.{Builds, Cache, Caster}
  alias Bottle.Assembly.V1.BuildUpdated

  @callback broadcast_build_update(struct(), struct()) :: :ok
  @callback request_quantity_update() :: :ok
  @callback request_quantity_update(list()) :: :ok

  def broadcast_build_update(old, new) do
    message = BuildUpdated.new(old: Caster.cast(old), new: Caster.cast(new))
    Bottle.publish(message, source: "assembly")
  end

  def request_quantity_update(component_ids \\ []) do
    component_ids
    |> Assembly.InventoryService.request_quantity_update()
    |> Stream.each(fn {:ok, resp} -> Cache.update_quantity_available(resp.component.id, resp.available) end)
    |> Stream.run()

    Builds.recalculate_statues()

    :ok
  end
end
