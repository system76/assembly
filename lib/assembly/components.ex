defmodule Assembly.Components do
  @moduledoc """
  Maintains all fo the inventory component logic
  """

  alias Assembly.Cache

  def update_quantity_available(component_id, quantity),
    do: Cache.put(component_id, quantity)

  def quantity_available(component_id) do
    case Cache.get(component_id) do
      {:error, _reason} ->
        # TODO: Handle errors
        nil

      {:ok, value} ->
        value
    end
  end
end
