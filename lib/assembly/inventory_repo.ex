defmodule Assembly.InventoryRepo do
  @moduledoc """
  Communication to our inventory microservice (or inventory database currently)
  """

  use Ecto.Repo,
    otp_app: :assembly,
    adapter: Ecto.Adapters.MyXQL

  import Ecto.Query

  @doc """
  Gets a list of all inventory skus in our system and the current available
  count of parts for that sku.
  """
  def get_sku_counts() do
    query =
      from(s in "inventory_skus",
        left_join: p in "inventory_parts", on: s.id == p.sku_id,
        where: is_nil(p.assembly_build_id),
        where: is_nil(p.rma_description),
        where: p.location_id not in ^excluded_picking_locations(),
        group_by: s.id,
        select: {s.id, count(p.id)}
      )

    query
    |> Assembly.InventoryRepo.all()
    |> Map.new()
  end

  defp excluded_picking_locations() do
    Application.get_env(:assembly, :excluded_picking_locations, [])
  end
end
