defmodule Canvas.Mixfile do
  use Mix.Project

  def project do
    [app: :canvas,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     description: description]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:wx_utils, "~> 0.0.2"}]
  end

  defp package do
    %{ licenses: ["MIT"],
       maintainers: ["James Edward Gray II"],
       links: %{"GitHub" => "https://github.com/JEG2/canvas"} }
  end

  defp description do
    """
    A library for building simple GUI canvases to draw on.
    """
  end
end
