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
  def handle_call(:component_list, _from, %{build_components: build_components} = build) do
    {:reply, build_components, build}
  end

  @impl true
  def handle_cast({:update_build, new_build}, _old_build) do
    {:noreply, new_build}
  end

  def handle_cast(:determine_status, %{build_components: build_components} = build) do
    Logger.info("Computing #{build.id} status")

    readyable? =
      Enum.all?(build_components, fn %{component_id: component_id, quantity: quantity_needed} ->
        quantity = Cache.quantity_available(component_id)
        not is_nil(quantity) and quantity >= quantity_needed
      end)

    {:ok, updated_build} =
      build
      |> Build.changeset(%{status: build_status(readyable?)})
      |> Repo.update()

    {:noreply, updated_build}
  end

  defp build_status(true), do: :ready
  defp build_status(false), do: :incomplete
end
