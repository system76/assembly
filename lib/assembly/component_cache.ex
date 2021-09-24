defmodule Assembly.ComponentCache do
  @moduledoc """
  Caches available quantities for components provided by the
  `Assembly.InventoryService`.
  """

  require Logger

  @doc """
  Returns the available amount of components. Will return 0 and try fetching
  the value for later if we don't have a value already cached.

  ## Examples

      iex> get("123")
      4

      iex> get("nope")
      0

  """
  def get(key) do
    case Cachex.get(__MODULE__, to_string(key)) do
      {:ok, nil} -> 0
      {:ok, value} -> value
      _ -> 0
    end
  end

  @doc """
  Updates the cached value of available components.

  ## Examples

      iex> put("123", 4)
      {:ok, true}

  """
  def put(key, value) do
    Logger.info("Updating quantity to #{value}", component_id: key)
    Cachex.put(__MODULE__, to_string(key), value)
  end
end
