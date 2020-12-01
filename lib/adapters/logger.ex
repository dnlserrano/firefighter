defmodule Firefighter.Adapters.Logger do
  require Logger

  @behaviour Firefighter.Adapter

  def pump(stream_name, records, delimiter, _opts) do
    Logger.info("Pushing to Firehose", stream: stream_name, records: records, delimiter: delimiter)

    {:ok, records}
  end
end
