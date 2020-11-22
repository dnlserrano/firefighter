defmodule Example do
  def run do
    pid = Process.whereis(:firefighter)
    for i <- 0..30, do: Firefighter.push(pid, "sample-data-#{i}")
    pid
  end
end
