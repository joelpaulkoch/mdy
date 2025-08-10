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

    port = Keyword.get(parsed, :port, default_port())

    path =
      case args do
        [] -> File.cwd!()
        [path] -> Path.expand(path)
        _else -> raise "at max. one positional argument allowed: PATH"
      end

    Logger.info("Serves your files under #{path} at http://localhost:#{port}/files/")

    case FileSystem.start_link(dirs: [path], name: MDy.Monitor) do
      {:ok, _pid} ->
        Logger.info("Monitoring files at #{path} for refreshs")

      {:error, error} ->
        Logger.warning("Failed to start monitoring for refreshs: #{inspect(error)}")
    end

    children = [
      {Bandit, plug: {MDy.Router, %{path: path, port: port}}, scheme: :http, port: port}
    ]

    opts = [strategy: :one_for_one, name: MDy.Supervisor]

    Supervisor.start_link(children, opts) |> tap(fn _ -> try_open_browser(port) end)
  end

  def default_port(), do: 4141

  defp try_open_browser(port) do
    {command, args} = :os.type() |> command_args()

    try do
      System.cmd(command, args ++ ["localhost:#{port}"], into: [], stderr_to_stdout: true)
    rescue
      _error -> :error
    end
  end

  defp command_args({:win32, _}) do
    {"cmd", ["/c", "start"]}
  end

  defp command_args({:unix, :darwin}) do
    {"open", []}
  end

  defp command_args({:unix, :linux}) do
    {"xdg-open", []}
  end
end
