defmodule Assembly.GenServers.Build do
  @moduledoc """
  A GenServer instance that runs for every `Assembly.Schemas.Build` to keep
  track of available `Assembly.Schemas.BuildComponent` and the availability
  status.
  """

  use GenServer, restart: :transient

  require Logger

  alias Assembly.{AdditiveMap, Option, Repo, Schemas}

  def start_link(%Schemas.Build{} = build) do
    GenServer.start_link(__MODULE__, build, name: name(build))
  end

  defp name(%Schemas.Build{hal_id: id}), do: name(id)
  defp name(id), do: {:via, Registry, {Assembly.BuildRegistry, to_string(id)}}

  @impl true
  def init(%Schemas.Build{} = build) do
    Logger.metadata(build_id: build.hal_id)
    Process.send_after(self(), :update_status, 0)
    {:ok, %{build: build}}
  end

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state.build, state}
  end

  @impl true
  def handle_call(:get_demand, _from, %{build: %{options: options}} = state) do
    if state.build.status in [:incomplete, :ready] do
      demand =
        Enum.reduce(options, %{}, fn o, map ->
          AdditiveMap.add(map, o.component_id, o.quantity)
        end)

      {:reply, demand, state}
    else
      {:reply, %{}, state}
    end
  end

  @impl true
  def handle_cast({:update_build, %{status: :built} = build}, state) do
    Logger.info("Stopping GenServer due to built status")
    emit_build_updated(state.build, build)
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:update_build, build}, state) do
    Logger.info("Updating build data", resource: inspect(%{old: state.build, new: build}))
    emit_build_updated(state.build, build)
    Process.send_after(self(), :update_status, 0)
    {:noreply, %{state | build: build}}
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

  defp emit_build_updated(old_build, new_build) do
    events_module().broadcast_build_update(old_build, new_build)
  end

  defp events_module, do: Application.get_env(:assembly, :events)
end
