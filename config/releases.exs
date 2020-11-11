import Config

config =
  "CONFIG"
  |> System.fetch_env!()
  |> Jason.decode!()

config :assembly,
  producer:
    {BroadwaySQS.Producer,
     queue_url: config["SQS_QUEUE_URL"],
     config: [
       access_key_id: config["SQS_ACCESS_KEY_ID"],
       secret_access_key: config["SQS_SECRET_ACCESS_KEY"],
       region: config["SQS_REGION"]
     ]}

config :assembly, Assembly.InventoryRepo,
 database: config["INVENTORY_DB_NAME"],
 username: config["INVENTORY_DB_USERNAME"],
 password: config["INVENTORY_DB_PASSWORD"],
 hostname: config["INVENTORY_DB_HOSTNAME"]

config :assembly, Assembly.Repo,
 database: config["DB_NAME"],
 username: config["DB_USERNAME"],
 password: config["DB_PASSWORD"],
 hostname: config["DB_HOSTNAME"]
