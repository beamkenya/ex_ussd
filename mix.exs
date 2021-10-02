defmodule ExUssd.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ussd,
      version: "1.0.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: "ExUssd lets you create simple, flexible, and customizable USSD interface.",
      deps: deps(),
      package: package(),
      name: "ExUssd",
      source_url: "https://github.com/beamkenya/ex_ussd.git",
      docs: [
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
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.15", only: [:test, :dev]}
    ]
  end
end
