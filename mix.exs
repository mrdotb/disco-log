defmodule DiscoLog.MixProject do
  use Mix.Project

  def project do
    [
      app: :disco_log,
      aliases: aliases(),
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DiscoLog.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:ecto, "~> 3.11"},
      {:jason, "~> 1.1"},
      {:plug, "~> 1.10"},
      {:req, "~> 0.5.0"},
      {:logger_backends, "~> 1.0.0"},
      # Dev dependencies
      {:mox, "~> 1.2", only: [:test]},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.33", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19 or ~> 1.0", only: [:dev]},
      {:plug_cowboy, "~> 2.0", only: :dev}
    ]
  end

  defp aliases do
    [
      dev: "run --no-halt dev.exs"
    ]
  end
end
