defmodule Hydra.Mixfile do
  use Mix.Project

  def project do
    [app: :hydra,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: escript,
     deps: deps]
  end

  def escript do
    [main_module: Hydra,
     path: "bin/hydra",
     embedd_elixir: true]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:timex, :ibrowse],
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
      {:timex, "~> 0.16.2"},
      {:statistics, "~> 0.2.0"},
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.1"}
    ]
  end
end
