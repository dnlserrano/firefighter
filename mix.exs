defmodule Firefighter.MixProject do
  use Mix.Project

  def project do
    [
      app: :firefighter,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [ExAws, ExAws.Firehose]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mox, "~> 1.0", only: [:test]}
    ]
  end
end
