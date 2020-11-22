import Mox
defmock(Firefighter.FirehoseMock, for: Firefighter.Adapter)

Application.put_env(:firefighter, :firehose, Firefighter.FirehoseMock)

Logger.configure(level: :warn)
ExUnit.start()
