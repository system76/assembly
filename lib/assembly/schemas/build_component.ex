defmodule Assembly.Schemas.BuildComponent do
  use Ecto.Schema

  import Ecto.Changeset

  alias Assembly.Schemas.Build
  alias __MODULE__, as: BuildComponent

  schema "build_components" do
    field :component_id, :integer
    field :quantity, :integer, default: 1

    belongs_to Build, :build
  end

  def changeset(%BuildComponent{} = build_component, params) do
    build_component
    |> cast(params, [:build_id, :component_id, :quantity])
    |> validate_required([:build_id, :component_id, :quantity])
    |> assoc_constraint(:build)
  end
end
