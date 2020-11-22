if Code.ensure_loaded?(ExAws.Firehose) do
  defmodule Firefighter.Adapters.ExAws do
    require Logger

    @behaviour Firefighter.Adapter

    def pump(stream_name, records, _opts) do
      result =
        ExAws.Firehose.put_record_batch(stream_name, records)
        |> ExAws.request()

      case result do
        {:ok, response} -> {:ok, response}
        {:error, error} -> {:error, error}
        error -> {:error, error}
      end
    end
  end
end
