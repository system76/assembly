defmodule Assembly.Events do
  @moduledoc """
  Encapsulate sending messages over RPC and Rabbit
  """

  require Logger

  alias Assembly.Caster
  alias Bottle.Assembly.V1.{BuildUpdated, ComponentDemandUpdated}

  @callback broadcast_build_update(map(), map()) :: :ok
  @callback broadcast_component_demand(String.t(), integer()) :: :ok
  @callback request_quantity_update(list()) :: :ok

  @source "assembly"

  def broadcast_build_update(old, new) do
    Logger.info("Broadcasting build update", build_id: new.hal_id)

    message = BuildUpdated.new(old: Caster.cast(old), new: Caster.cast(new))
    Bottle.publish(message, source: @source)
  end

  def broadcast_component_demand(component_id, demand) do
    Logger.info("Broadcasting new demand of #{demand}", component_id: component_id)

    message = ComponentDemandUpdated.new(component_id: component_id, quantity: demand)
    Bottle.publish(message, source: @source)
  end
end
