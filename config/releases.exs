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
    {BroadwaySQS.Producer,
     queue_url: config["SQS_URL"],
     config: [
       access_key_id: config["AWS_ACCESS_KEY_ID"],
       secret_access_key: config["AWS_SECRET_ACCESS_KEY"],
       region: config["AWS_REGION"]
     ]}

config :ex_aws,
  access_key_id: config["AWS_ACCESS_KEY_ID"],
  secret_access_key: config["AWS_SECRET_ACCESS_KEY"],
  region: config["AWS_REGION"]

config :appsignal, :config,
  push_api_key: config["APPSIGNAL_KEY"],
  env: config["ENVIRONMENT"]
