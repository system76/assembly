defmodule Assembly.Build do
  @moduledoc """
  Each process represents an active build watching for inventory changes and updating its status accordingly
  """

  use GenServer

  alias Assembly.{Builder, Components}
  alias Bottle.Assembly.V1.Build

  def start_link(%Build{} = build) do
    GenServer.start_link(__MODULE__, build)
  end

  @impl true
  def init(%Build{} = build) do
    {:ok, build}
  end

  @impl true
  def handle_cast(:determine_status, %Build{build_components: components, status: current_status} = build) do
    readyable? =
      Enum.all?(components, fn %{id: component_id, quantity: quantity_needed} ->
        {:ok, quantity} = Components.quantity_available(component_id)
        not is_nil(quantity) and quantity >= quantity_needed
      end)

    build = %Build{build | status: build_status(readyable?)}

    if (current_status == :BUILD_STATUS_READY) ^^^ readyable? do
      Builder.status_change(build, current_status)
    end

    {:noreply, build}
  end

  defp build_status(true), do: :BUILD_STATUS_READY
  defp build_status(false), do: :BUILD_STATUS_INCOMPLETE
end
