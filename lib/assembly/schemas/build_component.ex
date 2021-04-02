defmodule Assembly.Schemas.BuildComponent do
  use Ecto.Schema

  import Ecto.Changeset

  alias Assembly.Schemas.Build
  alias __MODULE__, as: BuildComponent

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "build_components" do
    field :component_id, :string
    field :quantity, :integer, default: 1

    belongs_to :build, Build

    timestamps()
  end

  def changeset(%BuildComponent{} = build_component, params) do
    build_component
    |> cast(params, [:build_id, :component_id, :quantity])
    |> validate_required([:component_id, :quantity])
    |> assoc_constraint(:build)
  end
end
