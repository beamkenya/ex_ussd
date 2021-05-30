defmodule ExUssd.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ussd,
      version: "0.1.3",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: "ExUssd lets you create simple, flexible, and customizable USSD interface.",
      deps: deps(),
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
      {:phoenix_live_view, "0.15.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
