defmodule Firefighter do
  @moduledoc """
  Documentation for `Firefighter`.
  """

  use GenServer
  require Logger

  @default_batch_size 40
  @default_flush_grace_period 30_000
  @default_interval 2_000

  defstruct [
    :delivery_stream_name,
    :batch_size,
    :interval,
    :records,
    :timer,
    :flush_grace_period,
    :flush_start,
    :extra
  ]

  def start_link(opts \\ []) do
    delivery_stream_name =
      opts[:delivery_stream_name] ||
        raise "need to provide :delivery_stream_name where to pump data to in Firehose"

    batch_size = opts[:batch_size] || @default_batch_size
    interval = opts[:interval] || @default_interval
    flush_grace_period = opts[:flush_grace_period] || @default_flush_grace_period
    extra = opts[:extra] || []
    name = opts[:name] || __MODULE__

    records = :queue.new()

    state = %__MODULE__{
      delivery_stream_name: delivery_stream_name,
      batch_size: batch_size,
      interval: interval,
      records: records,
      flush_grace_period: flush_grace_period,
      extra: extra
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def push(pid, record) do
    GenServer.cast(pid, {:push, record})
  end

  def config(pid) do
    GenServer.call(pid, :config)
  end

  def clear(pid) do
    GenServer.call(pid, :clear)
  end

  def records(pid) do
    GenServer.call(pid, :records)
  end

  @impl GenServer
  def init(
        %__MODULE__{
          delivery_stream_name: delivery_stream_name,
          batch_size: batch_size,
          interval: interval,
          flush_grace_period: flush_grace_period
        } = state
      ) do
    Logger.debug("Starting Firefighter",
      batch_size: batch_size,
      interval: interval,
      delivery_stream_name: delivery_stream_name,
      flush_grace_period: flush_grace_period
    )

    Process.flag(:trap_exit, true)

    timer = Process.send_after(self(), :tick, interval)
    {:ok, %{state | timer: timer}}
  end

  @impl GenServer
  def handle_cast({:push, record}, %__MODULE__{records: records} = state) do
    records = :queue.in(record, records)
    {:noreply, %{state | records: records}}
  end

  @impl GenServer
  def handle_call(:config, _from, state) do
    config = Map.from_struct(state)
    {:reply, config, state}
  end

  @impl GenServer
  def handle_call(:clear, _from, %__MODULE__{records: records} = state) do
    length = :queue.len(records)
    records = :queue.new()

    {:reply, length, %{state | records: records}}
  end

  @impl GenServer
  def handle_call(:records, _from, %__MODULE__{records: records} = state) do
    {:reply, records, state}
  end

  @impl GenServer
  def handle_info(:tick, %__MODULE__{interval: interval} = state) do
    Logger.debug("Ticking Firefighter")

    {batch, remaining} = get_records(state)
    pump(batch, state)

    timer = Process.send_after(self(), :tick, interval)
    {:noreply, %{state | records: remaining, timer: timer}}
  end

  @impl GenServer
  def terminate(reason, %__MODULE__{timer: timer} = state) do
    Process.cancel_timer(timer)
    Logger.debug("Terminating Firefighter", reason: reason)

    start_time = current_time_in_milliseconds()
    flush(%{state | flush_start: start_time})
  end

  defp flush(
         %__MODULE__{
           interval: interval,
           flush_grace_period: flush_grace_period,
           flush_start: flush_start,
           records: records
         } = state
       ) do
    cond do
      :queue.is_empty(records) ->
        Logger.debug("Flushed Firefighter")

      current_time_in_milliseconds() - flush_start >= flush_grace_period ->
        remaining = :queue.len(records)
        Logger.error("Stopping flush after grace period", remaining: remaining)

      true ->
        {batch, remaining} = get_records(state)
        pump(batch, state)

        Process.sleep(interval)

        flush(%{state | records: remaining})
    end
  end

  defp get_records(%__MODULE__{records: records, batch_size: batch_size}) do
    cond do
      :queue.is_empty(records) ->
        {[], records}

      :queue.len(records) > batch_size ->
        {batch, remaining} = :queue.split(batch_size, records)
        {:queue.to_list(batch), remaining}

      true ->
        {:queue.to_list(records), :queue.new()}
    end
  end

  defp pump([], _state), do: :noop

  defp pump(records, %__MODULE__{delivery_stream_name: delivery_stream_name, extra: extra}) do
    case firehose().pump(delivery_stream_name, records, extra) do
      {:ok, _result} ->
        Logger.debug("Successfully pumped data to Firehose", records: records)

      error ->
        Logger.error("Error pumping data to Firehose", error: error)
    end
  end

  defp current_time_in_milliseconds do
    System.monotonic_time(:millisecond)
  end

  defp firehose, do: Application.get_env(:firefighter, :firehose, Firefighter.Firehose)
end
