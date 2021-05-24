defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {App.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:ex_ussd, git: "https://github.com/lenileiro/ex_ussd.git", branch: "main"},
      {:plug, "~> 1.9"},
      {:cowboy, "~> 2.7"},
      {:plug_cowboy, "~> 2.2"},
      {:jason, "~> 1.2"}
    ]
  end
end
