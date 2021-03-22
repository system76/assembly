defmodule Assembly.Builds do
  @moduledoc """
  Functions for managing or interacting with the build queue
  """

  import Ecto.Query

  require Logger

  alias Assembly.Repo
  alias Assembly.Schemas.Build

  def new(%Bottle.Assembly.V1.Build{} = build) do
    with {:ok, new_build} <- create_build_and_components(build) do
      [result] = start_children([new_build])
      result
    end
  end

  def update(%Bottle.Assembly.V1.Build{} = build) do
    query =
      from b in Build,
        left_join: c in assoc(b, :build_components),
        where: b.hal_id == ^build.id,
        preload: [build_components: c]

    params = build_params(build)
    build = Repo.one(query)
    changeset = Build.changeset(build, params)

    with {:ok, updated_build} <- Repo.update(changeset),
         [{_, pid}] <- Registry.lookup(Assembly.Registry, to_string(updated_build.id)),
         :ok <- Registry.unregister(Assembly.Registry, to_string(updated_build.id)) do
      update_build_process(pid, updated_build)
    end
  end

  defp update_build_process(pid, %Build{status: :built}) do
    DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid)
  end

  defp update_build_process(pid, %Build{} = build),
    do: GenServer.cast(pid, {:updated_build, build})

  def load_builds do
    query =
      from b in Build,
        left_join: c in assoc(b, :build_components),
        where: b.status != :built,
        preload: [build_components: c]

    query
    |> Repo.all()
    |> start_children()
  end

  def recalculate_statues do
    Assembly.BuildSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _type, _modules} -> GenServer.cast(pid, :determine_status) end)
  end

  defp build_status(:BUILD_STATUS_BUILT), do: :built
  defp build_status(:BUILD_STATUS_INPROGRESS), do: :inprogress
  defp build_status(:BUILD_STATUS_READY), do: :ready
  defp build_status(_), do: :incomplete

  defp component_params(%{component: %{id: id}, quantity: quantity}) do
    %{
      component_id: id,
      quantity: quantity
    }
  end

  defp build_params(build) do
    %{
      hal_id: build.id,
      model: build.model,
      order_id: to_string(build.order.id),
      status: build_status(build.status),
      build_components: Enum.map(build.build_components, &component_params/1)
    }
  end

  defp create_build_and_components(build) do
    params = build_params(build)

    %Build{}
    |> Build.changeset(params)
    |> Repo.insert()
  end

  defp start_children(builds) do
    Enum.map(builds, fn build ->
      {:ok, pid} = DynamicSupervisor.start_child(Assembly.BuildSupervisor, {Assembly.Build, build})
      Registry.register(Assembly.Registry, to_string(build.id), pid)
      GenServer.cast(pid, :determine_status)

      {:ok, pid}
    end)
  end
end
