import Config

config :assembly,
  producer: {Broadway.DummyProducer, []},
  warmup: fn -> :ok end

config :assembly, Assembly.Repo,
  username: "postgres",
  password: "postgres",
  database: "assembly_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :amqp,
  connections: [
    rabbitmq_conn: [
      username: "assembly",
      password: "system76",
      host: "localhost",
      port: 5672
    ]
  ],
  channels: [
    events: [connection: :rabbitmq_conn]
  ]
