defmodule Firefighter.Adapter do
  @callback pump(
              stream_name :: binary(),
              records :: [binary()],
              delimiter :: binary(),
              opts :: keyword()
            ) ::
              {:ok, any()}
end
