defmodule Assembly.Schemas.Build do
  use Ecto.Schema

  import Ecto.Changeset

  alias Assembly.Schemas.BuildComponent
  alias __MODULE__, as: Build

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "builds" do
    field :hal_id, :integer
    field :model, :string
    field :order_id, :string
    field :status, BuildStatusEnum

    has_many :build_components, BuildComponent, on_replace: :delete

    timestamps()
  end

  def changeset(%Build{} = build, params) do
    build
    |> cast(params, [:hal_id, :model, :order_id, :status])
    |> validate_required([:hal_id, :model, :order_id])
    |> cast_assoc(:build_components)
  end
end
