defmodule DiscoLog.MixProject do
  use Mix.Project

  @source_url "https://github.com/mrdotb/disco-log"
  @version "1.0.3"

  def project do
    [
      app: :disco_log,
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: @source_url,
      docs: [
        main: "DiscoLog",
        formatters: ["html"],
        extra_section: "GUIDES",
        extras: [
          "guides/getting-started.md",
          "guides/advanced-configuration.md",
          "guides/standalone-presence.md"
        ],
        api_reference: false,
        main: "getting-started"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DiscoLog.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/mrdotb/disco-log"
      },
      maintainers: ["mrdotb", "martosaur"],
      files: ~w(lib LICENSE mix.exs README.md .formatter.exs)s
    ]
  end

  defp description, do: "Use Discord as a logging service and error tracking solution"

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:plug, "~> 1.10"},
      {:req, "~> 0.5.6"},
      {:nimble_options, "~> 1.1"},
      {:mint_web_socket, "~> 1.0", optional: true},
      # Dev & test dependencies
      {:git_ops, "~> 2.7.2", only: [:dev]},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.33", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19 or ~> 1.0", only: [:dev]},
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:mox, "~> 1.1", only: :test},
      {:logger_handler_kit, "~> 0.1", only: :test},
      {:oban, "~> 2.19", only: [:dev]},
      {:ecto_sqlite3, "~> 0.19.0", only: [:dev]},
      {:bandit, "~> 1.7", only: [:dev]}
    ]
  end

  defp aliases do
    [
      dev: "run --no-halt dev.exs"
    ]
  end
end
