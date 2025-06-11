defmodule MDy.Router do
  use Plug.Router, copy_opts_to_assign: :init_opts

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
end
