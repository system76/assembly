import Config

config :assembly,
  ecto_repos: [Assembly.Repo],
  events: Assembly.Events,
  inventory_service_url: nil,
  producer:
    {BroadwaySQS.Producer,
     queue_url: "",
     config: [
       access_key_id: "",
       secret_access_key: "",
       region: "us-east-2"
     ]}

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

config :ex_aws,
  access_key_id: nil,
  secret_access_key: nil,
  region: nil

config :appsignal, :config,
  active: false,
  name: "Assembly"

config :grpc, start_server: true

import_config "#{Mix.env()}.exs"
