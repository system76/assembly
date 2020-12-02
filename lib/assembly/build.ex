defmodule Assembly.Build do
  @moduledoc """
  Each process represents an active build watching for inventory changes and updating its status accordingly
  """
  use GenServer

  require Logger

  alias Assembly.{Cache, Repo, Schemas.Build}

  def start_link(%Build{} = build) do
    GenServer.start_link(__MODULE__, build)
  end

  @impl true
  def init(%Build{} = build) do
    {:ok, build}
  end

  @impl true
  def handle_cast(:determine_status, %{build_components: components} = build) do
    readyable? =
      Enum.all?(components, fn %{id: component_id, quantity: quantity_needed} ->
        {:ok, quantity} = Cache.quantity_available(component_id)
        not is_nil(quantity) and quantity >= quantity_needed
      end)

    build = %Build{build | status: build_status(readyable?)}

    Repo.update(build)

    {:noreply, build}
  end

  defp build_status(true), do: :ready
  defp build_status(false), do: :incomplete
end
