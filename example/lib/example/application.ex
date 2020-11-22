defmodule Example.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Firefighter, [delivery_stream_name: "s3-stream", name: :firefighter, batch_size: 10]}
    ]

    opts = [strategy: :one_for_one, name: Example.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
