defmodule Assembly do
  @moduledoc """
  Assembly Line functionality
  """

  require Logger

  alias Assembly.{Build, Option}

  def warmup do
    Logger.info("Warming up")

    with :ok <- Build.warmup_builds() do
      Option.emit_component_demands()

      Build.get_component_demands()
      |> Map.keys()
      |> Option.request_component_quantity()
    end
  end
end
