defmodule Assembly.Repo do
  use Ecto.Repo,
    otp_app: :assembly,
    adapter: Ecto.Adapters.Postgres
end
