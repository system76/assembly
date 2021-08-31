defmodule Assembly.Builds do
  @moduledoc """
  Functions for managing or interacting with the build queue
  """

  import Ecto.Query

  require Logger

  alias Assembly.{Caster, Repo, Schemas.Build}

  def new(%Bottle.Assembly.V1.Build{} = build) do
    with {:ok, new_build} <- create_build_and_components(build) do
      [{:ok, pid, _build}] = start_children([new_build])
      GenServer.cast(pid, :determine_status)
      {:ok, pid}
    end
  end

  def update(%Bottle.Assembly.V1.Build{} = build) do
    query =
      from b in Build,
        left_join: c in assoc(b, :build_components),
        where: b.hal_id == ^build.id,
        preload: [build_components: c]

    params = Caster.cast(build)
    build = Repo.one(query)
    changeset = Build.changeset(build, params)

    with {:ok, updated_build} <- Repo.update(changeset),
         [{_, pid}] <- Registry.lookup(Assembly.Registry, build.id) do
      update_build_process(pid, updated_build)
    end
  end

  def get(%Bottle.Assembly.V1.Build{} = build) do
    case Registry.lookup(Assembly.Registry, build.id) do
      [{_, pid}] -> GenServer.call(pid, :get_build)
      _ -> nil
    end
  end

  def list do
    Assembly.BuildSupervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_build) end)
  end

  def start_builds do
    query =
      from b in Build,
        left_join: c in assoc(b, :build_components),
        where: b.status != :built,
        preload: [build_components: c]

    query
    |> Repo.all()
    |> start_children()
  end

  defp create_build_and_components(build) do
    params = Caster.cast(build)

    %Build{}
    |> Build.changeset(params)
    |> Repo.insert()
  end

  def recalculate_statues do
    Assembly.BuildSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _type, _modules} -> GenServer.cast(pid, :determine_status) end)
  end

  defp start_children(builds) do
    Enum.map(builds, fn build ->
      {:ok, pid} = DynamicSupervisor.start_child(Assembly.BuildSupervisor, {Assembly.Build, build})
      Registry.register(Assembly.Registry, to_string(build.hal_id), pid)
      GenServer.cast(pid, :determine_status)
      {:ok, pid, build}
    end)
  end

  defp update_build_process(pid, %Build{hal_id: hal_id, status: :built}) do
    Registry.unregister(Assembly.Registry, to_string(hal_id))
    DynamicSupervisor.terminate_child(Assembly.BuildSupervisor, pid)
  end

  defp update_build_process(pid, %Build{} = build) do
    GenServer.cast(pid, {:updated_build, build})
  end
end
