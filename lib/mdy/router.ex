defmodule MDy.Router do
  use Plug.Router

  plug(:assign_root_path)
  plug(:assign_port)
  plug(Plug.Static, at: "/", from: {:mdy, "priv/"})
  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "hello")
  end

  get "/websocket" do
    conn
    |> WebSockAdapter.upgrade(MDy.WebSocket, [], timeout: :infinity)
    |> halt()
  end

  forward("/files/", to: MDy.Plug)

  match _ do
    send_resp(conn, 404, "oops")
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
