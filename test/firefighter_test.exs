defmodule FirefighterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mox

  @firehose Firefighter.FirehoseMock

  setup [:verify_on_exit!, :set_mox_global, :prepare_stubs]

  test "start_link/1 requires :delivery_stream_name" do
    assert_raise RuntimeError, ~r/need to provide :delivery_stream_name/, fn ->
      Firefighter.start_link()
    end
  end

  test "start_link/1 provides defaults" do
    {:ok, ff} = Firefighter.start_link(delivery_stream_name: "s3-stream")

    config = Firefighter.config(ff)

    assert match?(
             %{
               delivery_stream_name: "s3-stream",
               batch_size: 40,
               interval: 2_000,
               flush_grace_period: 30_000,
               delimiter: "",
               extra: []
             },
             config
           )
  end

  test "start_link/1 may override defaults" do
    {:ok, ff} =
      Firefighter.start_link(
        delivery_stream_name: "s3-stream",
        batch_size: 10,
        interval: 3_000,
        flush_grace_period: 60_000,
        delimiter: "\n"
      )

    config = Firefighter.config(ff)

    assert match?(
             %{
               delivery_stream_name: "s3-stream",
               batch_size: 10,
               interval: 3_000,
               flush_grace_period: 60_000,
               delimiter: "\n"
             },
             config
           )
  end

  test "push/2 enqueues records" do
    expect(@firehose, :pump, 2, fn _stream, _records, _delimiter, _extra -> {:ok, "pumped"} end)

    {:ok, ff} =
      Firefighter.start_link(delivery_stream_name: "s3-stream", batch_size: 5, interval: 50)

    records =
      0..7
      |> Enum.to_list()
      |> Enum.map(fn i -> "sample-record-55-#{i}" end)

    records
    |> Enum.each(fn record -> Firefighter.push(ff, record) end)

    enqueued = Firefighter.records(ff)
    length = :queue.len(enqueued)
    assert length == 8
    assert :queue.to_list(enqueued) == records

    Process.sleep(150)

    enqueued = Firefighter.records(ff)
    length = :queue.len(enqueued)
    assert length == 0
  end

  test "clear/1 clears all enqueued records" do
    {:ok, ff} = Firefighter.start_link(delivery_stream_name: "s3-stream", batch_size: 5)

    records =
      0..7
      |> Enum.to_list()
      |> Enum.map(fn i -> "sample-record-55-#{i}" end)

    records
    |> Enum.each(fn record -> Firefighter.push(ff, record) end)

    enqueued = Firefighter.records(ff)
    length = :queue.len(enqueued)
    assert length == 8
    assert :queue.to_list(enqueued) == records

    Firefighter.clear(ff)

    enqueued = Firefighter.records(ff)
    length = :queue.len(enqueued)
    assert length == 0
  end

  test "pumps records at each :interval" do
    expect(@firehose, :pump, fn "s3-stream",
                                [
                                  "sample-record-73-0",
                                  "sample-record-73-1",
                                  "sample-record-73-2",
                                  "sample-record-73-3",
                                  "sample-record-73-4"
                                ],
                                "\n",
                                [] ->
      {:ok, "pumped"}
    end)

    expect(@firehose, :pump, fn "s3-stream",
                                [
                                  "sample-record-73-5",
                                  "sample-record-73-6",
                                  "sample-record-73-7"
                                ],
                                "\n",
                                [] ->
      {:ok, "pumped"}
    end)

    {:ok, ff} =
      Firefighter.start_link(
        delivery_stream_name: "s3-stream",
        batch_size: 5,
        interval: 50,
        delimiter: "\n"
      )

    0..7
    |> Enum.to_list()
    |> Enum.map(fn i -> "sample-record-73-#{i}" end)
    |> Enum.each(fn record -> Firefighter.push(ff, record) end)

    Process.sleep(70)

    enqueued = Firefighter.records(ff)
    length = :queue.len(enqueued)

    assert length == 3

    Process.sleep(70)

    enqueued = Firefighter.records(ff)
    length = :queue.len(enqueued)

    assert length == 0
  end

  test "does not pump if nothing enqueued" do
    expect(@firehose, :pump, 0, fn _stream, _records, _delimiter, _extra -> {:ok, "pumped"} end)

    {:ok, ff} =
      Firefighter.start_link(delivery_stream_name: "s3-stream", batch_size: 5, interval: 50)

    Process.sleep(100)

    enqueued = Firefighter.records(ff)
    length = :queue.len(enqueued)

    assert length == 0
  end

  test "when :interval kicks in but batch size not met, it still pumps that small batch" do
    expect(@firehose, :pump, fn "s3-stream", ["sample-record-0"], "", [] -> {:ok, "pumped"} end)

    {:ok, ff} =
      Firefighter.start_link(delivery_stream_name: "s3-stream", batch_size: 5, interval: 50)

    Firefighter.push(ff, "sample-record-0")

    Process.sleep(100)
  end

  test "when it fails to pump data to firehose, logs error" do
    expect(@firehose, :pump, fn "s3-stream", ["sample-record-0"], "", [] ->
      {:error, "pumping error"}
    end)

    log =
      capture_log(fn ->
        {:ok, ff} =
          Firefighter.start_link(delivery_stream_name: "s3-stream", batch_size: 5, interval: 50)

        Firefighter.push(ff, "sample-record-0")

        Process.sleep(100)
      end)

    assert log =~ ~r/Error pumping data to Firehose/
  end

  test "when terminating, flushes data within :flush_grace_period" do
    expect(@firehose, :pump, 3, fn "s3-stream", _records, "", [] -> {:ok, "pumped"} end)

    {:ok, ff} =
      Firefighter.start_link(delivery_stream_name: "s3-stream", batch_size: 5, interval: 50)

    for i <- 0..12, do: Firefighter.push(ff, "sample-record-162-#{i}")

    Process.sleep(120)
    Process.exit(ff, :normal)
    Process.sleep(100)
  end

  test "when terminating, logs error if it cannot flush all data within :flush_grace_period" do
    expect(@firehose, :pump, 3, fn "s3-stream", _records, "", [] ->
      {:ok, "pumped"}
    end)

    log =
      capture_log(fn ->
        {:ok, ff} =
          Firefighter.start_link(
            delivery_stream_name: "s3-stream",
            batch_size: 5,
            interval: 50,
            flush_grace_period: 10
          )

        for i <- 0..30, do: Firefighter.push(ff, "sample-record-175-#{i}")

        Process.sleep(110)
        Process.exit(ff, :normal)
        Process.sleep(300)
      end)

    assert log =~ ~r/Stopping flush after grace period/
  end

  defp prepare_stubs(_context) do
    stub(@firehose, :pump, fn _stream, _records, _delimiter, _extra -> {:ok, "pumped"} end)
    :ok
  end
end
