# 👨‍🚒 firefighter

Amazon Kinesis Data Firehose configurable queue supporting arbitrary adapters.

## Motivation

When you want to integrate with Amazon Kinesis Data Firehose, you will most likely want to batch the requests you do in order to not hit Amazon limits. Hence, you'd ideally have an abstraction that allows you to push data, automatically buffering it and pumping data to any given stream from time to time. This is what `firefighter` does.

You can configure different options (e.g., `:batch_size`, `:interval` and `:flush_graceful_period`) which should be tuned to your specific usage.

## Installation

The package can be installed by adding `firefighter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:firefighter, "~> 0.1.1"}
  ]
end
```

## Usage

You should configure `firefighter` in, e.g., `config/config.exs` and select your specific adapter.

```elixir
# config/config.exs

config :firefighter, :adapter, Firefighter.Adapters.ExAws
```

Adapters provide implementations for the underlying libraries you may use to pump data to Firehose. By default, we provide a logger adapter that just logs data. We also provide an adapter for [`ex_aws`](https://github.com/ex-aws/ex_aws) out of the box. It should be easy enough to expand on this to provide more adapters (e.g., a new adapter for [`aws-elixir`](https://github.com/aws-beam/aws-elixir)).

## Example

```elixir
# config/config.exs

config :firefighter, :adapter, Firefighter.Adapters.Logger
```

```elixir
# config/prod.exs

config :firefighter, :adapter, Firefighter.Adapters.ExAws
```

```elixir
# lib/example/application.ex

defmodule Example.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Firefighter, [name: :my_firefighter, delivery_stream_name: "s3-firehose", batch_size: 10]}
    ]

    opts = [strategy: :one_for_one, name: Example.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

```elixir
# lib/example.ex

defmodule Example do
  def run do
    pid = Process.whereis(:my_firefighter)
    for i <- 0..30, do: Firefighter.push(pid, "sample-data-#{i}")
    pid
  end
end
```

## License

    Copyright © 2020-present Daniel Serrano <danieljdserrano at protonmail>

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.

Made in Portugal :portugal: by [dnlserrano](https://dnlserrano.dev)
