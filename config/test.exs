import Config

config :assembly,
  cachex_opts: [name: Assembly.Cache],
  events: Assembly.MockEvents,
  producer: {Broadway.DummyProducer, []},
  warmup: fn -> :ok end

config :assembly, Assembly.Repo,
  username: "postgres",
  password: "postgres",
  database: "assembly_test",
  hostname: Map.get(System.get_env(), "DB_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

config :grpc, start_server: false
