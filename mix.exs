defmodule Firefighter.MixProject do
  use Mix.Project

  def project do
    [
      app: :firefighter,
      version: "0.3.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
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
      {:elixir_uuid, "~> 1.2"},
      {:ex_aws_firehose, ">= 0.0.0", optional: true},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:expublish, ">= 0.0.0", only: :dev},
      {:jason, "~> 1.2"},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp description do
    "Amazon Kinesis Data Firehose configurable queue supporting arbitrary adapters"
  end

  defp package do
    [
      maintainers: ["Daniel Serrano"],
      licenses: ["MIT"],
      links: %{
        github: "https://github.com/dnlserrano/firefighter",
        personal: "https://dnlserrano.dev"
      }
    ]
  end
end
