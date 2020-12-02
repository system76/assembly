defmodule Assembly.Repo do
  use Ecto.Repo,
    otp_app: :Assembly,
    adapter: Ecto.Adapters.Postgres
end
