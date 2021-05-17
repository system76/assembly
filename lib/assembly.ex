defmodule Assembly do
  @moduledoc """
  Assembly Line functionality 
  """

  require Logger

  def warmup do
    Logger.info("Warming up")

    builds = Assembly.Builds.start_builds()
    Logger.info("Started #{length(builds)} builds")

    components =
      builds
      |> Enum.flat_map(fn {:ok, _pid, build} -> build.build_components end)
      |> Enum.uniq()
      |> Enum.map(&to_string(&1.component_id))

    Logger.info("Requesting availability for #{length(components)} components")
    request_quantity_update(components)
  end

  defp events_module, do: Application.get_env(:assembly, :events)

  defp request_quantity_update(component_ids), do: events_module().request_quantity_update(component_ids)
end
