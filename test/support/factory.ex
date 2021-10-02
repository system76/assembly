defmodule Assembly.Factory do
  use ExMachina.Ecto, repo: Assembly.Repo

  alias Assembly.Schemas

  @hardset_datetime 0 |> DateTime.from_unix!() |> DateTime.to_iso8601()

  def bottle_build_factory do
    %Bottle.Assembly.V1.Build{
      id: sequence(:hal_id, &"123#{&1}"),
      status: :BUILD_STATUS_READY,
      build_components: [],
      missing_components: [],
      model: "test",
      order: Bottle.Fulfillment.V1.Order.new(id: sequence(:order_id, &"123#{&1}")),
      created_at: @hardset_datetime,
      updated_at: @hardset_datetime
    }
  end

  def bottle_build_component_factory do
    %Bottle.Assembly.V1.Build.BuildComponent{
      component: Bottle.Inventory.V1.Component.new(id: sequence(:component_id, &"123#{&1}")),
      quantity: 1
    }
  end

  def build_factory do
    %Schemas.Build{
      hal_id: sequence(:hal_id, &"123#{&1}"),
      model: "test",
      options: [],
      order_id: sequence(:order_id, &"123#{&1}"),
      status: :ready
    }
  end

  def option_factory do
    %Schemas.Option{
      component_id: sequence(:component_id, &"123#{&1}"),
      quantity: 1
    }
  end

  def supervise(records) when is_list(records), do: Enum.map(records, &supervise/1)

  def supervise(%Schemas.Build{} = build) do
    with {:ok, _pid} <- DynamicSupervisor.start_child(Assembly.BuildSupervisor, {Assembly.GenServers.Build, build}) do
      build
    end
  end
end
