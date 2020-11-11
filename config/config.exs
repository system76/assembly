use Mix.Config

config :assembly,
  producer:
    {BroadwaySQS.Producer,
     queue_url: "",
     config: [
       access_key_id: "",
       secret_access_key: "",
       region: "us-east-2"
     ]}

config :assembly,
  ecto_repos: [
    Assembly.InventoryRepo,
    Assembly.Repo
  ]

config :assembly, Assembly.InventoryRepo,
  database: "inventory",
  username: "system76",
  password: "system76",
  hostname: "localhost"

config :assembly, Assembly.Repo,
  database: "assembly",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :assembly,
  excluded_picking_locations: []

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

config :appsignal, :config,
  active: false,
  name: "Assembly"

import_config "#{Mix.env()}.exs"
