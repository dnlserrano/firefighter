if Code.ensure_loaded?(ExAws.Firehose) do
  defmodule Firefighter.Adapters.ExAws do
    require Logger

    @behaviour Firefighter.Adapter

    def pump(stream_name, records, delimiter, _opts) do
      record_batch =
        records
        |> Enum.map(fn record ->
          record <> delimiter
        end)

      result =
        ExAws.Firehose.put_record_batch(stream_name, record_batch)
        |> ExAws.request()

      case result do
        {:ok, response} -> {:ok, response}
        {:error, error} -> {:error, error}
        error -> {:error, error}
      end
    end
  end
end
