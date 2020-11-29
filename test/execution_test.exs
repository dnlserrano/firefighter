defmodule ExecutionTest do
  import Mox
  use ExUnit.Case, async: true

  alias Firefighter.Execution

  @firefighter FirefighterMock
  @json JasonMock

  setup [:verify_on_exit!, :prepare_stubs]

  test "start/1" do
    %Execution{
      event_uuid: event_uuid,
      start_time: start_time,
      data: data
    } = Execution.start(%{user_id: "user-1", post_id: "post-123"})

    assert is_binary(event_uuid)
    assert is_integer(start_time)
    assert data.user_id == "user-1"
    assert data.post_id == "post-123"
  end

  test "record/2" do
    %Execution{data: %{age: age}} =
      Execution.start(%{user_id: "user-1", post_id: "post-123"})
      |> Execution.record(%{age: 29})

    assert age == 29
  end

  test "record_many/3" do
    %Execution{data: %{"photos" => photos}} =
      Execution.start(%{user_id: "user-1", post_id: "post-123"})
      |> Execution.record_many("photos", %{width: 720, height: 240})
      |> Execution.record_many("photos", %{width: 200, height: 300})

    assert photos == [
             %{width: 200, height: 300},
             %{width: 720, height: 240}
           ]
  end

  test "record_many/3 accepts a list" do
    %Execution{data: %{"photos" => photos}} =
      Execution.start(%{user_id: "user-1", post_id: "post-123"})
      |> Execution.record_many("photos", [
        %{width: 720, height: 240},
        %{width: 200, height: 300}
      ])

    assert photos == [
             %{width: 200, height: 300},
             %{width: 720, height: 240}
           ]
  end

  test "push/2 to ref by pid" do
    {:ok, pid} = Firefighter.start_link(delivery_stream_name: "s3-stream", name: :my_firefighter)
    expect(@firefighter, :push, fn ^pid, _record -> :ok end)
    expect(@json, :encode!, fn %{user_id: "user-1", post_id: "post-123"} -> :ok end)

    Execution.start(%{user_id: "user-1", post_id: "post-123"})
    |> Execution.push(pid)

    Process.exit(pid, :kill)
  end

  test "push/2 to ref by process name" do
    {:ok, pid} = Firefighter.start_link(delivery_stream_name: "s3-stream", name: :my_firefighter)

    expect(@firefighter, :push, fn ^pid, _record -> :ok end)
    expect(@json, :encode!, fn %{user_id: "user-1", post_id: "post-123", age: 29} -> :ok end)

    Execution.start(%{user_id: "user-1", post_id: "post-123"})
    |> Execution.record(%{age: 29})
    |> Execution.push(:my_firefighter)

    Process.exit(pid, :kill)
  end

  test "push/2 to ref by process name for non-existing process" do
    expect(@firefighter, :push, 0, fn _pid, _record -> :ok end)

    assert_raise ArgumentError, ~r/No process found for id my_firefighter/, fn ->
      Execution.start(%{user_id: "user-1", post_id: "post-123"})
      |> Execution.push(:my_firefighter)
    end
  end

  defp prepare_stubs(_context) do
    stub(@json, :encode!, fn map -> Jason.encode!(map) end)
    :ok
  end
end
