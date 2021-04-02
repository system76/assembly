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
  inventory_service_url: config["INVENTORY_SERVICE_URL"],
  producer:
    {BroadwayRabbitMQ.Producer,
     queue: config["RABBITMQ_QUEUE_NAME"],
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

config :ex_aws,
  access_key_id: config["AWS_ACCESS_KEY_ID"],
  secret_access_key: config["AWS_SECRET_ACCESS_KEY"],
  region: config["AWS_REGION"]

config :appsignal, :config,
  push_api_key: config["APPSIGNAL_KEY"],
  env: config["ENVIRONMENT"]
