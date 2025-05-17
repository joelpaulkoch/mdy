defmodule MDy.Plug do
  import Plug.Conn

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
    root = Keyword.get(opts, :path, File.cwd!())
    path = Path.join(root, conn.request_path)

    with {:ok, content} <- File.read(path),
         {:ok, html} <- render_html(content, path) do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, html)
    else
      {:error, {:not_implemented, message}} -> send_resp(conn, 501, message)
      {:error, :enoent} -> send_resp(conn, 404, "file does not exist")
      {:error, error} -> send_resp(conn, 500, "#{error}")
    end
  end

  defp render_html(content, path) do
    cond do
      markdown?(path) ->
        {:ok, Earmark.as_html!(content) |> append_mermaid() |> append_reload()}

      html?(path) ->
        {:ok, append_reload(content)}

      true ->
        {:error, {:not_implemented, "no markdown or html, don't know what to do"}}
    end
  end

  defp append_mermaid(html) do
    html <>
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

  defp append_reload(html) do
    html <>
      """
      <script>
        function reloadPage() {
          window.location.reload();
        }
        setInterval(reloadPage, 10000);
      </script>
      """
  end
end
