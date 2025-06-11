defmodule MDy.Plug do
  import Plug.Conn
  require EEx

  def init(options) do
    options
  end

  defp supported?(path) do
    markdown?(path) or html?(path)
  end

  defp markdown?(path) do
    Path.extname(path) |> String.ends_with?("md")
  end

  defp html?(path) do
    Path.extname(path) |> String.ends_with?("html")
  end

  def call(conn, _opts) do
    path = Path.join([conn.assigns.init_opts.path | conn.path_info])
    port = conn.assigns.init_opts.port

    files = File.ls!(conn.assigns.init_opts.path) |> Enum.filter(&supported?/1)

    render_file(conn, path, port, files)
  end

  defp render_file(conn, path, port, files) do
    with {:ok, content} <- File.read(path),
         {:ok, html} <- render_html(content, path, port, files) do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, html)
    else
      {:error, :eisdir} ->
        html = render(error: "pick a file", files: files)
        send_resp(conn, 200, html)

      {:error, {:not_implemented, message}} ->
        html = render(error: message, files: files)
        send_resp(conn, 501, html)

      {:error, :enoent} ->
        html = render(error: "file does not exist", files: files)
        send_resp(conn, 404, html)

      {:error, error} ->
        html = render(error: "#{inspect(error)}", files: files)
        send_resp(conn, 500, html)
    end
  end

  defp render_html(content, path, port, files) do
    cond do
      markdown?(path) ->
        html = Earmark.as_html!(content)

        {:ok, render(html: html, scripts: [mermaid(), reload(port)], files: files)}

      html?(path) ->
        {:ok, render(html: content, scripts: [reload(port)], files: files)}

      true ->
        {:error, {:not_implemented, "no markdown or html, don't know what to do"}}
    end
  end

  EEx.function_from_string(
    :defp,
    :render,
    """

    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css" >
      </head>

      <div style="display: flex; padding: 1rem;"> 
        <aside>
          <nav>
            <ul>
              <%= assigns[:files] && for file <- @files do %> 
                <li>
                  <a href="<%= file %>"> <%= file %> </a>
                </li>
              <% end %>
            </ul>
          </nav>
        </aside>

        <main class="container-fluid">
          <%= if assigns[:error] do %>
            <%= @error %>
          <% else %>
            <%= @html %>
          <% end %>
        </main>

      </div>

      <%= assigns[:scripts] && for script <- @scripts || [] do %>
        <%= script %>
      <% end %>
    </html>
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
