defmodule ExUssd.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ussd,
      version: "0.1.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "ExUssd lets you create simple, flexible, and customizable USSD interface.",
      package: package(),
      deps: deps(),
      name: "ExUssd",
      source_url: "https://github.com/beamkenya/ex_ussd.git",
      docs: [
        # The main page in the docs
        main: "readme",
        canonical: "http://hexdocs.pm/ex_ussd",
        source_url: "https://github.com/beamkenya/ex_ussd.git",
        extras: ["README.md", "contributing.md"]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExUssd.Application, []}
    ]
  end

  defp package do
    [
      name: "ex_ussd",
      licenses: ["MIT"],
      maintainers: [],
      links: %{
        "GitHub" => "https://github.com/beamkenya/ex_ussd.git",
        "README" => "https://hexdocs.pm/ex_ussd/readme.html"
      },
      homepage_url: "https://github.com/beamkenya/ex_ussd"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:defnamed, "~> 0.1"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:sweet_xml, "~> 0.6.6"}
    ]
  end
end
