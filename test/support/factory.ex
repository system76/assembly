defmodule Assembly.Factory do
  use ExMachina.Ecto, repo: Assembly.Repo

  alias Assembly.Schemas.{
    Build,
    BuildComponent
  }

  def build_factory do
    %Build{
      hal_id: sequence(:hal_id, &"123#{&1}"),
      status: :incomplete
    }
  end

  def build_component_factory do
    %BuildComponent{
      build: build(:build),
      component_id: sequence(:component_id, &"123#{&1}"),
      quantity: 1
    }
  end
end
