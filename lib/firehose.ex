defmodule Firefighter.Firehose do
  require Logger

  @behaviour Firefighter.Adapter
  @default_adapter Firefighter.Adapters.Logger

  def pump(stream_name, records, delimiter, opts) do
    adapter().pump(stream_name, records, delimiter, opts)
  end

  defp adapter, do: Application.get_env(:firefighter, :adapter, @default_adapter)
end
