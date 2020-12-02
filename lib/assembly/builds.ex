defmodule Assembly.Builds do
  @moduledoc """
  Functions for managing or interacting with the build queue
  """

  import Ecto.Query

  require Logger

  alias Assembly.Repo
  alias Assembly.Schemas.{Build, BuildComponent}

  def new(%Bottle.Assembly.V1.Build{} = build) do
    with {:ok, new_build} <- create_build_and_components(build) do
      start_children([new_build])
    end
  end

  def load_builds do
    query =
      from b in Build,
        join: c in assoc(b, :build_components),
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

  defp build_status(:BUILD_STATUS_INCOMPLETE), do: :incomplete
  defp build_status(:BUILD_STATUS_READY), do: :ready

  defp component_changeset(%{component: %{id: id}, quantity: quantity}) do
    BuildComponent.changeset(%BuildComponent{}, %{component_id: id, quantity: quantity})
  end

  defp create_build_and_components(build) do
    params = %{
      hal_id: build.id,
      status: build_status(build.status)
    }

    build_component_changesets = Enum.all?(build.build_components, &component_changeset/1)

    %Build{}
    |> Build.changeset(params)
    |> Ecto.Changeset.put_assoc(:build_components, build_component_changesets)
    |> Repo.insert()
  end

  defp start_children(builds) do
    Enum.each(builds, &DynamicSupervisor.start_child(Assembly.BuildSupervisor, {Assembly.Build, &1}))
    recalculate_statues()
  end
end
