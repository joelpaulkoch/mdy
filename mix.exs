defmodule MDy.MixProject do
  use Mix.Project

  def project do
    [
      app: :mdy,
      version: "0.1.1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def cli do
    [
      preferred_envs: [release: :prod]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MDy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, "~> 1.4"},
      {:plug, "~> 1.17"},
      {:websock_adapter, "~> 0.5.8"},
      {:file_system, "~> 1.0"},
      {:bandit, "~> 1.6"},
      {:burrito, "~> 1.0"}
    ]
  end

  def releases do
    [
      mdy: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos_x86_64: [os: :darwin, cpu: :x86_64],
            macos_aarch64: [os: :darwin, cpu: :aarch64],
            linux_gnu_x86_64: [os: :linux, cpu: :x86_64],
            linux_gnu_aarch64: [os: :linux, cpu: :aarch64],
            # linux_musl_x86_64: [os: :linux_musl, cpu: :x86_64],
            # linux_musl_aarch64: [os: :linux_musl, cpu: :aarch64],
            windows_x86_64: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end
end
