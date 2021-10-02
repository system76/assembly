defmodule Assembly.Schemas.Option do
  @moduledoc """
  The `Assembly.Schemas.Option` schema handles every component attached
  to a `Assembly.Schemas.Build`. A component is every option selected when an
  order is created. This can be a specific kind of GPU, Memory, or even
  software like a specific operating system.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Assembly.Schemas

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          component_id: String.t(),
          quantity: non_neg_integer(),
          build: Schemas.Build.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "build_components" do
    field :component_id, :string
    field :quantity, :integer, default: 1

    belongs_to :build, Schemas.Build

    timestamps()
  end

  def changeset(%__MODULE__{} = build_component, params) do
    build_component
    |> cast(params, [:id, :build_id, :component_id, :quantity])
    |> validate_required([:component_id, :quantity])
    |> assoc_constraint(:build)
  end
end
