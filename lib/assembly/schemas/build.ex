defmodule Assembly.Schemas.Build do
  @moduledoc """
  The `Assembly.Schemas.Build` schema handles every build we know about. A build
  is the smallest form of a fulfillable object. For instance, when you create
  an order of 3 different Thelio desktops, we create 3 different builds. Each
  one can then be built seperatly, and shipped seperatly.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Assembly.Schemas

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          hal_id: integer(),
          model: String.t(),
          order_id: String.t(),
          status: :incomplete | :ready | :inprogress | :built,
          options: [Schemas.Option.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @foreign_key_type :binary_id
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "builds" do
    field :hal_id, :integer
    field :model, :string
    field :order_id, :string
    field :status, Ecto.Enum, values: [:incomplete, :ready, :inprogress, :built]

    has_many :options, Schemas.Option, on_replace: :delete

    timestamps()
  end

  def changeset(%__MODULE__{} = build, params) do
    build
    |> cast(params, [:hal_id, :model, :order_id, :status])
    |> validate_required([:hal_id, :model, :order_id])
    |> cast_assoc(:options)
  end
end
