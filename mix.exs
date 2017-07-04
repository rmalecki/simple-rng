defmodule Simplerng.Mixfile do
  use Mix.Project

  def project do
    [app: :simplerng,
     version: "0.1.0",
     name: "SimpleRNG",
     source_url: "https://github.com/rmalecki/simple-rng",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
    mod: {SimpleRNG, []}]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README", "LICENSE*"],
      maintainers: ["Rouven Malecki"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/rmalecki/simple-rng"}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    []
  end
end
