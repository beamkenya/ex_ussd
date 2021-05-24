defmodule ExUssd.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ussd,
      version: "0.1.3",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExUssd.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "0.15.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
