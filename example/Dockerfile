FROM hexpm/elixir:1.11.2-erlang-23.1.2-ubuntu-xenial-20201014

WORKDIR /home/app/service

RUN mix deps.get \
  && mix compile

COPY . .

CMD ["iex", "-S", "mix"]
