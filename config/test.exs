use Mix.Config

config :assembly,
  producer: {Broadway.DummyProducer, []}

config :assembly, Assembly.InventoryRepo,
  pool: Ecto.Adapters.SQL.Sandbox

config :assembly, Assembly.Repo,
  pool: Ecto.Adapters.SQL.Sandbox
