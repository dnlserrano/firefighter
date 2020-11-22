defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Example.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_aws, "~> 2.1"},
      {:ex_aws_firehose, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:hackney, "~> 1.16"},
      {:firefighter, path: "/home/app/service"},
    ]
  end
end
