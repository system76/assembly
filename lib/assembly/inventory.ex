defmodule Assembly.Inventory do
  @moduledoc """
  A process that holds inventory counts for every sku, and broadcasts when
  the count changes.
  """

  use GenServer

  import Logger

  alias Assembly.InventoryRepo
  alias Phoenix.PubSub

  @update_interval 1000 * 60 * 15

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def get_sku_counts() do
    GenServer.call(__MODULE__, :get_sku_counts)
  end

  def get_sku_count(sku) do
    GenServer.call(__MODULE__, {:get_sku_counts, sku})
  end

  @impl true
  def init(_) do
    schedule_update()

    {:ok, InventoryRepo.get_sku_counts()}
  end

  @impl true
  def handle_call(:get_sku_counts, _, counts) do
    {:reply, counts, counts}
  end

  @impl true
  def handle_call({:get_sku_count, sku}, _, counts) do
    {:reply, Map.get(counts, sku, 0), counts}
  end

  @impl true
  def handle_info(:update, old_counts) do
    schedule_update()

    Logger.debug("Fetching new inventory counts")

    new_counts = InventoryRepo.get_sku_counts()

    old_counts
    |> Map.merge(new_counts)
    |> Enum.filter(fn {sku, new_count} ->
      Map.get(old_counts, sku, 0) !== new_count
    end)
    |> Enum.each(fn {sku, new_count} ->
      Logger.debug("#{sku} count change to #{new_count}")
      PubSub.broadcast(Assembly.InventoryPubSub, to_string(sku), {sku, new_count})
    end)

    {:noreply, new_counts}
  end

  defp schedule_update() do
    Process.send_after(self(), :update, @update_interval)
  end
end
