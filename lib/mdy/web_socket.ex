defmodule MDy.WebSocket do
  require Logger

  def init(options) do
    FileSystem.subscribe(MDy.Monitor)

    {:ok, options}
  end

  def handle_in({message, payload}, state) do
    Logger.info("Received unknown message #{inspect(message)} with payload #{inspect(payload)}")
    {:ok, state}
  end

  def terminate(:timeout, state) do
    Logger.warning("Closing websocket due to timeout")
    {:ok, state}
  end

  def terminate(:error, error) do
    Logger.warning("Terminating with error #{inspect(error)}")
    {:error, error}
  end

  def terminate(error, state) do
    Logger.warning("Terminating with error #{inspect(error)}")
    {:error, state}
  end

  def handle_info({:file_event, _pid, {_path, events}}, state) do
    if :modified in events do
      {:push, {:text, "reload"}, state}
    else
      {:ok, state}
    end
  end

  def handle_info({:file_event, _pid, :stop}, state) do
    Logger.info("Stopped monitoring files")
    {:ok, state}
  end

  def handle_info(event, state) do
    Logger.info("Received unknown event #{inspect(event)} with state #{inspect(state)}")
    {:ok, state}
  end
end
