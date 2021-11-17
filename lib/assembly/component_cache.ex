defmodule Assembly.ComponentCache do
  @moduledoc """
  Caches available quantities for components provided by the
  `Assembly.InventoryService`.
  """

  use Cachex.Hook

  require Logger

  @doc false
  def init(_), do: {:ok, nil}

  @doc """
  Returns the available amount of components. Will return 0 and try fetching
  the value for later if we don't have a value already cached.

  ## Examples

      iex> get("123")
      4

      iex> get("nope")
      0

  """
  @spec get(String.t()) :: non_neg_integer()
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

      iex> put("123", 0)
      {:ok, true}

      iex> put("123", 4)
      {:ok, true}

  """
  @spec put(String.t(), non_neg_integer()) :: {:ok, true}
  def put(key, 0) do
    Logger.info("Updating quantity to 0", component_id: key)
    Cachex.del(__MODULE__, to_string(key))
  end

  def put(key, value) do
    Logger.info("Updating quantity to #{value}", component_id: key)
    Cachex.put(__MODULE__, to_string(key), value)
  end

  @doc """
  A `Cachex.Hook` that handles notify builds when anything changes.
  """
  def handle_notify({action, _params} = msg, _results, _last) do
    if action in [:put, :clear] do
      Assembly.Build.update_build_status()
    end

    {:ok, msg}
  end
end
