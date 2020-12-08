defmodule Assembly.Schemas.Build do
  use Ecto.Schema

  import Ecto.Changeset

  alias Assembly.Schemas.BuildComponent
  alias __MODULE__, as: Build

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
