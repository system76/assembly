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
      [result] = start_children([new_build])
      result
    end
  end

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

  defp build_status(:BUILD_STATUS_INCOMPLETE), do: :incomplete
  defp build_status(:BUILD_STATUS_READY), do: :ready

  defp component_params(%{id: build_id}, %{component: %{id: id}, quantity: quantity}) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    %{
      build_id: build_id,
      component_id: id,
      quantity: quantity,
      inserted_at: now,
      updated_at: now
    }
  end

  defp create_build_and_components(build) do
    params = %{
      hal_id: build.id,
      status: build_status(build.status)
    }

    changeset = Build.changeset(%Build{}, params)

    with {:ok, new_build} <- Repo.insert(changeset) do
      params = Enum.map(build.build_components, &component_params(new_build, &1))
      Repo.insert_all(BuildComponent, params)

      {:ok, new_build}
    end
  end

  defp start_children(builds) do
    Enum.map(builds, fn build ->
      {:ok, pid} = DynamicSupervisor.start_child(Assembly.BuildSupervisor, {Assembly.Build, build})
      GenServer.cast(pid, :determine_status)

      {:ok, pid}
    end)
  end
end
