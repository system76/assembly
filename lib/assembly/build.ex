defmodule Assembly.Build do
  @moduledoc """
  A genserver for builds. It listens for changes to part counts from inventory
  and updates it's buildable status.
  """

  use GenServer

  import Logger

  alias Phoeinx.PubSub

  def start_link(build) do
    GenServer.start_link(__MODULE__, [build], name: registry_name(build))
  end

  @impl true
  def init(build) do
    # Find all configurations, get all the skus for each configuration, and
    # subscribe to all of em

    {:ok, %{
      build: build,
      configurations: [],
      skus: []
    }}
  end

  defp registry_name(%{id: build_id}), do: registry_name(build_id)
  defp registry_name(build_id), do: {:via, Registry, {:build, build_id}}

  defp unsubscribe(skus) do
    Enum.each(skus, fn sku ->
      PubSub.unsubscribe(Assembly.InventoryPubSub, to_string(sku))
    end)
  end

  defp subscribe(skus) do
    Enum.each(skus, fn sku ->
      PubSub.subscribe(Assembly.InventoryPubSub, to_string(sku))
    end)
  end
end
