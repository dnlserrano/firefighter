import Mox

defmodule JasonBehaviour do
  @callback encode(any()) ::
              {:ok, String.t()} | {:error, Jason.EncodeError.t() | Exception.t()}
end

defmock(Firefighter.FirehoseMock, for: Firefighter.Adapter)
defmock(FirefighterMock, for: Firefighter)
defmock(JasonMock, for: JasonBehaviour)

Application.put_env(:firefighter, :firehose, Firefighter.FirehoseMock)
Application.put_env(:firefighter, :firefighter, FirefighterMock)
Application.put_env(:firefighter, :json, JasonMock)

Logger.configure(level: :warn)
ExUnit.start()
