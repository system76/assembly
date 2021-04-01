defmodule Assembly.Cache do
  @moduledoc """
  Wraps get and puts to cache.
  Implements the Cachex reactive and proactive cache warming.
  """

  require Logger

  def fallback(component_id) do
    events_module().request_quantity_update([component_id])
    {:ok, []}
  end

  def quantity_available(component_id) do
    {:ok, value} = Cachex.get(__MODULE__, component_id)
    if is_nil(value), do: 0, else: value
  end

  def update_quantity_available(component_id, quantity) do
    Logger.info("Updating #{component_id} quantity to #{quantity}")
    Cachex.put(__MODULE__, component_id, quantity)
  end

  defp events_module, do: Application.get_env(:assembly, :events)
end
