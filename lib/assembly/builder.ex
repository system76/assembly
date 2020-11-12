defmodule Assembly.Builder do
  @moduledoc """
  Functions for managing or interacting with the build queue
  """

  require Logger

  alias Assembly.Events

  def recalculate_statues do
    Assembly.BuildSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _type, _modules} -> GenServer.cast(pid, :determine_status) end)
  end

  def status_changed(%Build{} = build, old_status) do
    Logger.debug("Build #{build.id} status has changed to #{build.status} from #{old_status}")

    Events.broadcast_build_update(build_updated)
  end
end
