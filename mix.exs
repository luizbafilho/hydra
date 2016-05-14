defmodule Hydra.Mixfile do
  use Mix.Project

  def project do
    [app: :hydra,
     version: "0.0.1",
     elixir: "~> 1.2.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: escript,
     deps: deps]
  end

  def escript do
    [main_module: Hydra.CLI,
     path: "bin/hydra",
     embed_elixir: true]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:hackney],
     mod: {Hydra, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:statistics, "~> 0.4.0"},
      {:hackney, github: "benoitc/hackney", tag: "1.6.0"}
    ]
  end
end
