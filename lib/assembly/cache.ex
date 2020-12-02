defmodule Assembly.Cache do
  @moduledoc """
  Wraps get and puts to cache.
  Implements the Cachex reactive and proactive cache warming.
  """

  use Cachex.Warmer

  alias Assembly.Events

  @six_hours 60 * 6

  @impl true
  def execute(_state) do
    Events.request_quantity_update()
    :ignore
  end

  def fallback(component_id) do
    Events.request_quantity_update([component_id])
    :ignore
  end

  def get(component_id) do
    with {:ok, nil} <- Cachex.get(__MODULE__, component_id) do
      {:ok, 0}
    end
  end

  @impl true
  def interval,
    do: :timer.minutes(@six_hours)

  def put(component_id, quantity),
    do: Cachex.put(__MODULE__, component_id, quantity)
end
