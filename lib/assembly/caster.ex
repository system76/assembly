defmodule Assembly.Caster do
  @moduledoc """
  This module is responsible for casting Avalara responses into `Bottle` messages.
  """

  alias Assembly.Schemas
  alias Bottle.Assembly.V1.Build
  alias Bottle.Inventory.V1.Component
  alias Bottle.Fulfillment.V1.Order

  def cast(%Build{} = build) do
    %{
      id: Ecto.UUID.generate(),
      build_components: Enum.map(build.build_components, &parse_build_component/1),
      hal_id: build.id,
      inserted_at: build.created_at,
      missing_components: Enum.map(build.missing_components, &parse_build_component/1),
      model: build.model,
      order_id: to_string(build.order.id),
      status: parse_status(build.status),
      updated_at: build.updated_at
    }
  end

  def cast(%Schemas.Build{} = build) do
    Build.new(
      build_components: Enum.map(build.build_components, &parse_build_component/1),
      created_at: to_string(build.inserted_at),
      id: to_string(build.hal_id),
      missing_components: Enum.map(build.missing_components, &parse_build_component/1),
      model: build.model,
      order: Order.new(id: build.order_id),
      status: parse_status(build.status),
      updated_at: to_string(build.updated_at)
    )
  end

  defp parse_build_component(%Build.BuildComponent{component: %{id: id}, quantity: quantity}) do
    %{
      component_id: id,
      quantity: quantity
    }
  end

  defp parse_build_component(%Schemas.BuildComponent{} = build_component) do
    Build.BuildComponent.new(
      component: Component.new(id: build_component.component_id),
      quantity: build_component.quantity
    )
  end

  defp parse_status(:BUILD_STATUS_BUILT), do: :built
  defp parse_status(:BUILD_STATUS_INPROGRESS), do: :inprogress
  defp parse_status(:BUILD_STATUS_READY), do: :ready
  defp parse_status(:BUILD_STATUS_INCOMPLETE), do: :incomplete
  defp parse_status(:built), do: :BUILD_STATUS_BUILT
  defp parse_status(:incomplete), do: :BUILD_STATUS_INCOMPLETE
  defp parse_status(:inprogress), do: :BUILD_STATUS_INPROGRESS
  defp parse_status(:ready), do: :BUILD_STATUS_READY
  defp parse_status(_), do: :BUILD_STATUS_UNSPECIFIED
end
