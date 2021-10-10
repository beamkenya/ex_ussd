defmodule ExUssd.MixProject do
  use Mix.Project

  @source_url "https://github.com/beamkenya/ex_ussd.git"
  @version "1.0.1"

  def project do
    [
      app: :ex_ussd,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: "ExUssd lets you create simple, flexible, and customizable USSD interface.",
      deps: deps(),
      package: package(),
      source_url: @source_url,
      # Docs
      name: "ExUssd",
      docs: docs()
    ]
  end

  defp docs do
    [
      main: "ExUssd",
      groups_for_modules: [
        Nav: [
          ExUssd.Nav
        ]
      ],
      extras: [
        "CHANGELOG.md",
        "contributing.md",
        "README.md": [title: "Overview"]
      ],
      source_url: @source_url,
      source_ref: "v#{@version}"
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
      licenses: ["Apache-2.0"],
      maintainers: [],
      links: %{
        "GitHub" => @source_url,
        "README" => "https://hexdocs.pm/ex_ussd/readme.html"
      },
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "contributing.md"
      ],
      homepage_url: "https://github.com/beamkenya/ex_ussd"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.15", only: [:test, :dev]}
    ]
  end
end
