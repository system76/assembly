use Mix.Config

config :assembly,
  cachex_opts: [name: Assembly.Cache],
  events: Assembly.MockEvents,
  producer: {Broadway.DummyProducer, []}

config :assembly, Assembly.Repo,
  username: "postgres",
  password: "postgres",
  database: "assembly_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :grpc, start_server: false
