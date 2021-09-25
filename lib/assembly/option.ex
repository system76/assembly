defmodule Assembly.Option do
  @moduledoc """
  Helper functions for handling options.
  """

  alias Assembly.{AdditiveMap, Build, ComponentCache, Schemas}

  @doc """
  Emits component demand events for every known component.

  ## Examples

      iex> emit_component_demands()
      :ok

  """
  @spec emit_component_demands() :: :ok
  def emit_component_demands() do
    Enum.each(Build.get_component_demands(), fn {component_id, demand} ->
      events_module().broadcast_component_demand(component_id, demand)
    end)
  end

  @doc """
  Emits component demand event for a list of component ids. This will iterate
  over all builds and add up the demand to get the _total_ demand for the
  component.

  ## Examples

      iex> emit_component_demands(["A", "B", "C"])
      :ok

  """
  @spec emit_component_demands([String.t()]) :: :ok
  def emit_component_demands(component_ids) do
    filter = Enum.map(component_ids, &to_string/1)

    filter
    |> Enum.reduce(%{}, &AdditiveMap.set(&2, &1, 0))
    |> AdditiveMap.merge(Build.get_component_demands())
    |> Enum.filter(fn {component_id, _} -> component_id in filter end)
    |> Enum.each(fn {component_id, demand} ->
      events_module().broadcast_component_demand(component_id, demand)
    end)
  end

  @doc """
  Updates the `Assembly.ComponentCache` with current available quantity from
  the inventory service.

  ## Examples

      iex> request_component_quantity(["A", "B", "C"])
      :ok

  """
  @spec request_component_quantity([String.t()]) :: :ok
  def request_component_quantity(component_ids \\ []) do
    component_ids
    |> Assembly.InventoryService.request_quantity_update()
    |> Stream.map(fn {:ok, res} -> res end)
    |> Stream.map(fn %{component: %{id: k}, total_available_quantity: v} -> {k, v} end)
    |> Stream.each(fn {k, v} -> ComponentCache.put(k, v) end)
    |> Stream.run()
  end

  @doc """
  Returns a list of `Assembly.Schemas.Option` that we do not have enough
  quantity for.

  ## Examples

      iex> unavailable_options([%Schemas.Option{}])
      []

  """
  @spec unavailable_options([Schemas.Option]) :: [Schemas.Option]
  def unavailable_options(options) do
    Enum.reject(options, &(ComponentCache.get(&1.component_id) >= &1.quantity))
  end

  defp events_module, do: Application.get_env(:assembly, :events)
end
