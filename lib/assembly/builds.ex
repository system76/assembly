defmodule Assembly.Builds do
  @moduledoc """
  Functions for managing or interacting with the build queue
  """

  require Logger

  alias Bottle.Assembly.V1.Build

  def new(%Build{} = build) do
    DynamicSupervisor.start_child(Assembly.BuildSupervisor, {Assembly.Build, build})
    recalculate_statues()
  end

  def recalculate_statues do
    Assembly.BuildSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _type, _modules} -> GenServer.cast(pid, :determine_status) end)
  end

  def status_changed(%Build{} = build, old_status) do
    Logger.debug("Build #{build.id} status has changed to #{build.status} from #{old_status}")

    Assembly.Events.broadcast_build_update(build_updated)
  end
end
