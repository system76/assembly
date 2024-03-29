defmodule Assembly.GenServers.Build do
  @moduledoc """
  A GenServer instance that runs for every `Assembly.Schemas.Build` to keep
  track of available `Assembly.Schemas.BuildComponent` and the availability
  status.
  """

  use GenServer, restart: :transient

  require Logger

  alias Assembly.{AdditiveMap, Demand, Option, Repo, Schemas}

  def start_link(%Schemas.Build{} = build) do
    GenServer.start_link(__MODULE__, build, name: name(build))
  end

  defp name(%Schemas.Build{hal_id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Assembly.BuildRegistry, to_string(id)}}

  @impl true
  def init(%Schemas.Build{} = build) do
    Logger.metadata(build_id: build.hal_id)

    emit_component_demands(build)
    Process.send_after(self(), :update_status, 0)

    {:ok, %{build: build}}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state.build, state}
  end

  @impl true
  def handle_call(:get_demand, _from, %{build: %{options: options}} = state) do
    Logger.debug("got get_demand for build #{inspect(state.build)}")

    demand =
      cond do
        state.build.status in [:incomplete, :ready] ->
          build_demand_response(options)

        state.build.status == :inprogress ->
          # We send demand for parts  that are not available, assuming
          # they have not been picked. In case parts are not picked for any other reason
          # and build is benched, this will decrease the demand and result in an incorrect value.
          # FIXME: Send picking status of every option.
          unavailable_options = Option.unavailable_options(options)
          build_demand_response(unavailable_options)

        true ->
          %{}
      end

    Logger.debug("get_demand returned demand #{inspect(demand)}")

    {:reply, demand, state}
  end

  @impl true
  def handle_cast({:update_build, %{status: :built} = build}, state) do
    Logger.info("Stopping GenServer due to built status")

    emit_build_updated(state.build, build)
    emit_component_demands(state.build)

    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:update_build, build}, state) do
    Logger.info("Updating build data", resource: inspect(%{old: state.build, new: build}))

    emit_build_updated(state.build, build)
    emit_component_demands(state.build)
    Process.send_after(self(), :update_status, 0)

    {:noreply, %{state | build: build}}
  end

  @impl true
  def handle_cast(:delete_build, state) do
    Logger.info("Stopping GenServer due to build being deleted")

    emit_component_demands(state.build)

    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:update_status, %{build: %{status: status} = build} = state) when status in [:incomplete, :ready] do
    new_build_status =
      case Option.unavailable_options(build.options) do
        [] -> :ready
        _missing_options -> :incomplete
      end

    if new_build_status != build.status do
      Logger.info("Updating build status to #{new_build_status}")

      new_build =
        build
        |> Schemas.Build.changeset(%{"status" => to_string(new_build_status)})
        |> Repo.update!()
        |> Repo.preload([:options])

      emit_build_updated(build, new_build)
      {:noreply, %{state | build: new_build}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:update_status, state), do: {:noreply, state}

  defp build_demand_response(options) do
    Enum.reduce(options, %{}, fn o, map ->
      AdditiveMap.add(map, o.component_id, o.quantity)
    end)
  end

  defp emit_build_updated(old_build, new_build) do
    events_module().broadcast_build_update(old_build, new_build)
  end

  defp emit_component_demands(build) do
    case build do
      %{options: %Ecto.Association.NotLoaded{}} ->
        :ok

      %{options: options} ->
        # We iterate over all the options now so if the build gets stopped
        # (like it does once it's built), we can still iterate over all the data
        # and decrease our demand.
        options
        |> Enum.map(& &1.component_id)
        |> Enum.each(&Demand.emit_component/1)

      _ ->
        :ok
    end
  end

  defp events_module, do: Application.get_env(:assembly, :events)
end
