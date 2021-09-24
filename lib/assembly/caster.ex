defmodule Assembly.Caster do
  @moduledoc """
  This module is responsible for casting Avalara responses into `Bottle` messages.
  """

  def cast(%Bottle.Assembly.V1.Build{} = build) do
    %{
      hal_id: build.id,
      model: build.model,
      order_id: to_string(build.order.id),
      status: parse_status(build.status),
      options:
        maybe_map(build.build_components, fn c ->
          %{component_id: c.component.id, quantity: c.quantity}
        end),
      inserted_at: build.created_at,
      updated_at: build.updated_at
    }
  end

  def cast(%Assembly.Schemas.Build{} = build) do
    Bottle.Assembly.V1.Build.new(
      id: to_string(build.hal_id),
      model: build.model,
      order: %{id: build.order_id},
      status: parse_status(build.status),
      build_components:
        maybe_map(build.options, fn o ->
          %{component: %{id: to_string(o.component_id)}, quantity: o.quantity}
        end),
      missing_components: [],
      created_at: to_string(build.inserted_at),
      updated_at: to_string(build.updated_at)
    )
  end

  defp maybe_map(values, f) when is_list(values), do: Enum.map(values, f)
  defp maybe_map(_, _f), do: []

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
