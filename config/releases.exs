import Config

config =
  "CONFIG"
  |> System.fetch_env!()
  |> Jason.decode!()

config :assembly,
  producer:
    {BroadwaySQS.Producer,
     queue_url: config["sqs_queue_url"],
     config: [
       access_key_id: config["sqs_access_key_id"],
       secret_access_key: config["sqs_secret_access_key"],
       region: config["sqs_region"]
     ]}
