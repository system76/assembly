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
    Logger.info("Computing #{build.hal_id} status")
    readyable? = Enum.all?(build_components, &components_available?/1)

    updated_build =
      build
      |> Build.changeset(%{status: build_status(readyable?)})
      |> update_build()

    {:noreply, updated_build}
  end

  defp build_status(true), do: :ready
  defp build_status(false), do: :incomplete

  defp components_available?(%{component_id: component_id, quantity: quantity_needed}) do
    quantity =
      component_id
      |> to_string()
      |> Cache.quantity_available()

    not is_nil(quantity) and quantity >= quantity_needed
  end

  defp events_module, do: Application.get_env(:assembly, :events)

  defp update_build(%{changes: changes}) when %{} == changes do
    :ignored
  end

  defp update_build(changeset) do
    with {:ok, updated_build} <- Repo.update(changeset) do
      Logger.info("Broadcasting build #{updated_build.hal_id} state change")
      events_module().broadcast_build_update(changeset.data, updated_build)

      updated_build
    end
  end
end
