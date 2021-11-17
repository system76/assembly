defmodule Assembly.Build do
  @moduledoc """
  High level functions to managing the database persistant layer, and GenServer
  cache layer of build information.
  """

  import Ecto.Query

  require Logger

  alias Assembly.AdditiveMap
  alias Assembly.GenServers
  alias Assembly.Option
  alias Assembly.Schemas
  alias Assembly.Repo

  @supervisor Assembly.BuildSupervisor
  @registry Assembly.BuildRegistry

  @doc """
  Lists all builds that are not built.

  ## Examples

      iex> list_builds()
      [%Schemas.Build{}]
  """
  @spec list_builds() :: [Schemas.Build.t()]
  def list_builds() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_info) end)
    |> Enum.into([])
  end

  @doc """
  Starts a `Assembly.GenServers.Build` instance for everything not built in the
  database. This is used on application startup.
  """
  @spec warmup_builds() :: :ok
  def warmup_builds() do
    query =
      from b in Schemas.Build,
        left_join: o in assoc(b, :options),
        preload: [options: o]

    for build <- Repo.all(query) do
      DynamicSupervisor.start_child(@supervisor, {GenServers.Build, build})
    end

    :ok
  end

  @doc """
  Grabs information about a single build via the hal ID.

  ## Examples

      iex> get_build(id)
      %Schemas.Build{}

  """
  @spec get_build(String.t()) :: Schemas.Build.t() | nil
  def get_build(id) do
    case Registry.lookup(@registry, to_string(id)) do
      [{pid, _value}] -> GenServer.call(pid, :get_info)
      _ -> nil
    end
  catch
    :exit, {:normal, _} -> :ok
  end

  @doc """
  Creates a new instance of a build in the database, then starts up the
  `Assembly.GenServers.Build` instance for it.

  ## Examples

      iex> create_build(valid_attrs)
      {:ok, %Schemas.Build()}

      iex> create_build(invalid_attrs)
      {:error, %Ecto.Changeset{}}

  """
  @spec create_build(map()) :: {:ok, Schemas.Build.t()} | {:error, Ecto.Changeset.t()}
  def create_build(attrs) do
    with changeset <- Schemas.Build.changeset(%Schemas.Build{}, attrs),
         {:ok, build} <- Repo.insert(changeset),
         preloaded_build <- Repo.preload(build, [:options]),
         {:ok, _pid} <- DynamicSupervisor.start_child(@supervisor, {GenServers.Build, preloaded_build}) do
      {:ok, build}
    end
  end

  @doc """
  Updates a builds data in both the persistant layer, and the GenServer layer.
  Please note that the status is calculated asynchronously, and the returned
  status may not contain the changes.

  ## Examples

      iex> update_build(%Schemas.Build{}, valid_attrs)
      {:ok, %Schemas.Build()}

      iex> update_build(%Schemas.Build{}, invalid_attrs)
      {:error, %Ecto.Changeset{}}

  """
  @spec update_build(Schemas.Build.t(), map()) :: {:ok, Schemas.Build.t()} | {:error, Ecto.Changeset.t()}
  def update_build(build, attrs) do
    with %{changes: changes} = changeset when map_size(changes) > 0 <- Schemas.Build.changeset(build, attrs),
         {:ok, updated_build} <- Repo.update(changeset),
         preloaded_build <- Repo.preload(updated_build, [:options]) do
      case Registry.lookup(@registry, to_string(preloaded_build.hal_id)) do
        [{pid, _value}] ->
          GenServer.cast(pid, {:update_build, preloaded_build})
          {:ok, preloaded_build}

        _ ->
          DynamicSupervisor.start_child(@supervisor, {GenServers.Build, preloaded_build})
          {:ok, preloaded_build}
      end
    else
      # No-op if no changes occure. Avoids sending build updated messages on the
      # queue, recalculating status, etc.
      %{errors: []} -> {:ok, build}
      %{changes: _} = changeset -> {:error, changeset}
    end
  end

  @doc """
  Picks an order via the hal ID given. This changes the status to `:inprogress`
  and prevents the status from being updated / recalculated later on.

  ## Examples

      iex> pick_build(id)
      {:ok, %Schemas.Build{}}

  """
  @spec pick_build(String.t()) :: {:ok, Schemas.Build.t()} | {:error, :not_found}
  def pick_build(id) do
    with build when not is_nil(build) <- Repo.get_by(Schemas.Build, hal_id: id),
         {:ok, updated_build} <- update_build(build, %{"status" => "inprogress"}) do
      {:ok, updated_build}
    else
      {:error, changeset} ->
        Logger.error("Unable to set build status to inprogress", resource: inspect(changeset))
        {:error, :not_found}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a build currently in queue. This will delete it from the database, but
  also stop the GenServer and recalculate the demand for components.

  ## Examples

      iex> delete_build(id)
      {:ok, %Schemas.Build{}}

  """
  @spec delete_build(String.t()) :: {:ok, Schemas.Build.t()} | {:error, Ecto.Changeset.t()} | {:error, :not_found}
  def delete_build(id) do
    with build when not is_nil(build) <- get_build(id),
         [{pid, _value}] <- Registry.lookup(@registry, to_string(id)) do
      GenServer.cast(pid, :delete_build)
      Repo.delete(build)
    else
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Iterates over all builds and recalculates their status. This is ran after our
  internal cache of component quantities is updated. This will ignore any build
  in the `:inprogress` or `:built` status because they can not switch to
  `:ready` or `:incomplete`.

  ## Examples

      iex> update_build_status()
      :ok

  """
  @spec update_build_status() :: :ok
  def update_build_status() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Stream.each(fn {_, pid, _type, _modules} -> send(pid, :update_status) end)
    |> Stream.run()
  end

  @doc """
  Iterates over all builds, fetches the component demands of all the selected
  options, and merges them together.

  ## Examples

      iex> get_component_demands()
      %{"A" => 4, "B" => 2, "C" => 3}

  """
  @spec get_component_demands() :: AdditiveMap.t()
  def get_component_demands() do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _type, _modules} -> GenServer.call(pid, :get_demand) end)
    |> Enum.reduce(%{}, &AdditiveMap.merge/2)
  end

  @doc """
  Takes an ID, grabs all the components required for it, adds it with any other
  builds that require the same component, then emits the component demand
  updated event.

  ## Examples

      iex> emit_component_demands_for_build("123")
      :ok

  """
  @spec emit_component_demands_for_build(String.t()) :: :ok
  def emit_component_demands_for_build(id) do
    case get_build(id) do
      %{options: %Ecto.Association.NotLoaded{}} ->
        :ok

      %{options: options} ->
        options
        |> Enum.map(&Map.get(&1, :component_id))
        |> Option.emit_component_demands()

      _ ->
        :ok
    end
  end
end
