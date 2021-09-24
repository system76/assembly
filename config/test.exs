import Config

config :assembly,
  events: Assembly.MockEvents,
  producer: {Broadway.DummyProducer, []},
  warmup: fn -> :ok end

config :assembly, Assembly.Repo,
  username: "postgres",
  password: "postgres",
  database: "assembly_test",
  hostname: Map.get(System.get_env(), "DB_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

config :amqp,
  connections: [
    rabbitmq_conn: [
      username: "assembly",
      password: "system76",
      host: Map.get(System.get_env(), "RABBITMQ_HOST", "localhost"),
      port: 5672
    ]
  ],
  channels: [
    events: [connection: :rabbitmq_conn]
  ]

config :grpc, start_server: false
