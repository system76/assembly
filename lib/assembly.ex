defmodule Assembly do
  @moduledoc """
  Assembly Line functionality
  """

  require Logger

  def warmup do
    Logger.info("Warming up")

    with :ok <- Assembly.Build.warmup_builds() do
      Assembly.Build.get_component_demands()
      |> Map.keys()
      |> request_quantity_update()
    end
  end

  defp events_module, do: Application.get_env(:assembly, :events)

  defp request_quantity_update(component_ids), do: events_module().request_quantity_update(component_ids)
end
