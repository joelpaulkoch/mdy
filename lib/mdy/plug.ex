defmodule MDy.Plug do
  import Plug.Conn
  require EEx

  def init(options) do
    options
  end

  defp markdown?(path) do
    Path.extname(path) |> String.ends_with?("md")
  end

  defp html?(path) do
    Path.extname(path) |> String.ends_with?("html")
  end

  def call(conn, opts) do
    port = Keyword.get(opts, :port, MDy.Application.default_port())
    root = Keyword.get(opts, :path, File.cwd!())
    path = Path.join(root, conn.request_path)

    case conn.request_path do
      "/websocket" -> upgrade_to_websocket(conn)
      _else -> render_file(conn, path, port)
    end
  end

  defp upgrade_to_websocket(conn) do
    conn
    |> WebSockAdapter.upgrade(MDy.WebSocket, [], timeout: :infinity)
    |> halt()
  end

  defp render_file(conn, path, port) do
    with {:ok, content} <- File.read(path),
         {:ok, html} <- render_html(content, path, port) do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, html)
    else
      {:error, {:not_implemented, message}} -> send_resp(conn, 501, message)
      {:error, :enoent} -> send_resp(conn, 404, "file does not exist")
      {:error, error} -> send_resp(conn, 500, "#{error}")
    end
  end

  defp render_html(content, path, port) do
    cond do
      markdown?(path) ->
        html = Earmark.as_html!(content)

        {:ok, render(html: html, scripts: [mermaid(), reload(port)])}

      html?(path) ->
        {:ok, render(html: content, scripts: [reload(port)])}

      true ->
        {:error, {:not_implemented, "no markdown or html, don't know what to do"}}
    end
  end

  EEx.function_from_string(
    :defp,
    :render,
    """
    <head>
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.fluid.classless.min.css" >
    </head>

    <%= @html %>

    <%= for script <- @scripts do %>
      <%= script %>
    <% end %>
    """,
    [:assigns]
  )

  defp mermaid() do
    """
    <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

    const isDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

    mermaid.initialize({
      startOnLoad: false,
      theme: isDarkMode ? "dark" : "default"
    });

    await mermaid.run();

    </script>
    """
  end

  defp reload(port) do
    """
    <script>
      sock = new WebSocket("ws://localhost:#{port}/websocket")

      function reloadPage() {
        window.location.reload();
      }

      sock.addEventListener("message", (event) => {
          console.log(event);
          if (event.data === "reload") {
            sock.close(1000, "reloading");
            reloadPage();
          };
        }
      )

    </script>
    """
  end
end
