import Config

config :firefighter, adapter: Firefighter.Adapters.ExAws
config :firefighter, delimiter: "\n"

config :ex_aws,
  access_key_id: "123456",
  secret_access_key: "123456"

config :ex_aws, :firehose,
  scheme: "http://",
  host: "localstack",
  port: 4566,
  region: "eu-west-1"
