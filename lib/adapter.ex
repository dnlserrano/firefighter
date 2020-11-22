defmodule Firefighter.Adapter do
  @callback pump(stream_name :: binary(), records :: [binary()], opts :: keyword()) ::
              {:ok, any()}
end
