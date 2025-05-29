defmodule MDy.Router do
  use Plug.Router

  plug(:assign_root_path)
  plug(:assign_port)
  plug(Plug.Static, at: "/", from: {:mdy, "priv/"})
  plug(:match)
  plug(:dispatch)

  get "/websocket" do
    conn
    |> WebSockAdapter.upgrade(MDy.WebSocket, [], timeout: :infinity)
    |> halt()
  end

  forward("/files/", to: MDy.Plug)

  match _ do
    conn
    |> put_resp_header("location", "/files/")
    |> send_resp(303, "redirecting..")
  end

  defp assign_root_path(conn, opts) do
    root = Keyword.get(opts, :path, File.cwd!())

    put_private(conn, :path, root)
  end

  defp assign_port(conn, opts) do
    port = Keyword.get(opts, :port, MDy.Application.default_port())

    put_private(conn, :port, port)
  end
end
