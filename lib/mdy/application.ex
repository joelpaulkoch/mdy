defmodule MDy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    {parsed, args, _invalid} =
      Burrito.Util.Args.argv()
      |> OptionParser.parse(strict: [port: :integer])

    port = Keyword.get(parsed, :port, 4141)

    path =
      case args do
        [] -> File.cwd!()
        [path] -> Path.expand(path)
        _else -> raise "at max. one positional argument allowed: PATH"
      end

    Logger.info("Starting at #{path}")

    children = [
      {Bandit, plug: {MDy.Plug, path: path}, scheme: :http, port: port}
    ]

    opts = [strategy: :one_for_one, name: MDy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
