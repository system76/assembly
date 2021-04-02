defmodule Assembly.Caster do
  @moduledoc """
  This module is responsible for casting Avalara responses into `Bottle` messages.
  """

  alias Assembly.Schemas
  alias Bottle.Assembly.V1.Build
  alias Bottle.Fulfillment.V1.Order

  def cast(%Schemas.Build{} = build) do
    Build.new(
      created_at: build.inserted_at,
      id: build.id,
      model: build.modal,
      order: Order.new(id: build.order_id),
      status: parse_status(build.status),
      updated_at: build.updated_at
    )
  end

  defp parse_status(:built), do: :BUILD_STATUS_BUILT
  defp parse_status(:incomplete), do: :BUILD_STATUS_INCOMPLETE
  defp parse_status(:ready), do: :BUILD_STATUS_READY
  defp parse_status(:inprogress), do: :BUILD_STATUS_INPROGRESS
  defp parse_status(_), do: :BUILD_STATUS_UNSPECIFIED
end
