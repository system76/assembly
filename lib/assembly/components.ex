defmodule Assembly.Components do
  @moduledoc """
  Maintains all fo the inventory component logic
  """

  alias Assembly.Cache

  def update_quantity_available(component_id, quantity),
    do: Cache.put(component_id, quantity)

  def quantity_available(component_id) do
    {:ok, value} = Cache.get(component_id)
    value
  end
end
