defmodule Assembly.Schemas.Build do
  use Ecto.Schema

  import Ecto.Changeset

  alias Assembly.Schemas.BuildComponent
  alias __MODULE__, as: Build

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "builds" do
    field :status, BuildStatusEnum
    field :hal_id, :integer

    has_many :build_components, BuildComponent

    timestamps()
  end

  def changeset(%Build{} = build, params) do
    build
    |> cast(params, [:hal_id, :status])
    |> validate_required([:hal_id])
  end
end
