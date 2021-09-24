import Config

config =
  "CONFIG"
  |> System.fetch_env!()
  |> Jason.decode!()

config :assembly, Assembly.Repo,
  username: config["DB_USER"],
  password: config["DB_PASS"],
  database: config["DB_NAME"],
  hostname: config["DB_HOST"],
  port: config["DB_PORT"],
  pool_size: config["DB_POOL"]

config :assembly,
  producer:
    {BroadwayRabbitMQ.Producer,
     queue: config["RABBITMQ_QUEUE_NAME"],
     on_failure: :reject_and_requeue,
     connection: [
       username: config["RABBITMQ_USERNAME"],
       password: config["RABBITMQ_PASSWORD"],
       host: config["RABBITMQ_HOST"],
       port: config["RABBITMQ_PORT"],
       ssl_options: [verify: :verify_none]
     ]}

config :amqp,
  connections: [
    rabbitmq_conn: [
      username: config["RABBITMQ_USERNAME"],
      password: config["RABBITMQ_PASSWORD"],
      host: config["RABBITMQ_HOST"],
      port: config["RABBITMQ_PORT"],
      ssl_options: [verify: :verify_none]
    ]
  ],
  channels: [
    events: [connection: :rabbitmq_conn]
  ]

config :assembly, Assembly.InventoryServiceClient,
  enabled?: true,
  url: config["INVENTORY_SERVICE_URL"],
  ssl: true

config :assembly, Assembly.Tracer, env: config["ENVIRONMENT"]
