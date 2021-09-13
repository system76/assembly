defmodule Assembly.Build do
  @moduledoc """
  Each process represents an active build watching for inventory changes and updating its status accordingly
  """
  use GenServer

  require Logger

  alias Assembly.{Cache, Repo}
  alias Assembly.Schemas.{Build, BuildComponent}

  def start_link(%Build{} = build) do
    GenServer.start_link(__MODULE__, build)
  end

  @impl true
  def init(%Build{} = build) do
    Logger.metadata(build_id: build.hal_id)
    {:ok, build}
  end

  @impl true
  def handle_call(:component_list, _from, %{build_components: build_components} = build) do
    {:reply, build_components, build}
  end

  @impl true
  def handle_call(:get_build, _from, build) do
    {:reply, build, build}
  end

  @impl true
  def handle_cast({:updated_build, new_build}, old_build) do
    emit_updated_build(old_build, new_build)
    {:noreply, new_build}
  end

  def handle_cast(:determine_status, %{build_components: build_components} = build) do
    Logger.info("Computing status")
    missing_components = Enum.reduce(build_components, [], &components_available?/2)

    updated_build =
      build
      |> Map.put(:missing_components, missing_components)
      |> Build.changeset(%{status: build_status(build, missing_components)})
      |> update_build()

    {:noreply, updated_build}
  end

  defp build_status(%{status: :inprogress}, _missing_components), do: :inprogress
  defp build_status(_build, []), do: :ready
  defp build_status(_build, _missing_components), do: :incomplete

  defp components_available?(%{component_id: component_id, quantity: quantity_needed}, acc) do
    quantity =
      component_id
      |> to_string()
      |> Cache.quantity_available()

    available = quantity || 0

    if available < quantity_needed do
      [%BuildComponent{component_id: component_id, quantity: quantity_needed - quantity} | acc]
    else
      acc
    end
  end

  defp update_build(%{changes: changes, data: build}) when %{} == changes do
    build
  end

  defp update_build(changeset) do
    with {:ok, updated_build} <- Repo.update(changeset) do
      updated_build = %{updated_build | missing_components: changeset.data.missing_components}
      emit_updated_build(changeset.data, updated_build)
    end
  end

  defp emit_updated_build(old_build, updated_build) do
    Logger.info("Broadcasting build state change")
    events_module().broadcast_build_update(old_build, updated_build)

    updated_build
  end

  defp events_module, do: Application.get_env(:assembly, :events)
end
