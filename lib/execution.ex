defmodule Firefighter.Execution do
  @type execution :: %__MODULE__{}

  @callback start(data :: map) :: execution
  @callback record(exec :: execution, data :: map) :: execution
  @callback record_many(exec :: execution, name :: binary, data :: list | map) :: execution
  @callback push(exec :: execution, pid :: any) :: execution

  defstruct [
    :event_uuid,
    :event_time,
    :elapsed,
    data: %{}
  ]

  def start(ids) do
    %__MODULE__{
      event_uuid: uuid(),
      event_time: current_time_in_milliseconds(),
      data: ids
    }
  end

  def record(%__MODULE__{data: data} = execution, ids) do
    %{execution | data: Map.merge(data, ids)}
  end

  def record_many(%__MODULE__{} = execution, name, list_of_ids) when is_list(list_of_ids) do
    list_of_ids
    |> Enum.reduce(execution, fn ids, end_execution ->
      record_many(end_execution, name, ids)
    end)
  end

  def record_many(%__MODULE__{data: data} = execution, name, ids) when is_map(ids) do
    many = data[name] || []
    data = Map.put(data, name, [ids | many])
    %{execution | data: data}
  end

  def push(%__MODULE__{} = execution, id) when not is_pid(id) do
    case Process.whereis(id) do
      nil -> raise ArgumentError, "No process found for id #{id}"
      pid -> push(execution, pid)
    end
  end

  def push(%__MODULE__{event_time: event_time} = execution, pid) when is_pid(pid) do
    elapsed = current_time_in_milliseconds() - event_time
    execution = %{execution | elapsed: elapsed / 1_000}

    record = to_record(execution)
    firefighter().push(pid, record)

    execution
  end

  defp to_record(%__MODULE__{event_uuid: event_uuid, elapsed: elapsed, data: data}) do
    record =
      %{event_uuid: event_uuid, elapsed: elapsed}
      |> Map.merge(data)

    json().encode!(record)
  end

  defp uuid, do: UUID.uuid4()
  defp current_time_in_milliseconds, do: System.monotonic_time(:millisecond)

  defp firefighter, do: Application.get_env(:firefighter, :firefighter, Firefighter)
  defp json, do: Application.get_env(:firefighter, :json, Jason)
end
