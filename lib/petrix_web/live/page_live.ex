defmodule PetrixWeb.PageLive do
  use PetrixWeb, :live_view

  @tick 50
  @tick_variance -20..50

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, @tick)
    {:ok, assign(socket, query: "", results: %{}, nodes: make_nodes(20))}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @tick + Enum.random(@tick_variance))
    {:noreply, update(socket, :nodes, &alter_nodes/1)}
  end

  defp search(query) do
    if not PetrixWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end

  defp make_nodes(n) do
    range = 0..700

    for _ <- 0..n do
      %{x: dist(range), y: dist(range)}
    end
  end

  defp dist(range) do
    (Enum.random(range) + Enum.random(range)) / 2
  end

  defp alter_nodes(nodes) do
    Enum.map(nodes, &alter_node/1)
  end

  defp alter_node(node) do
    range = -10..10

    if Enum.random([true, false, false]) do
      %{x: node.x + Enum.random(range), y: node.y + Enum.random(range)}
    else
      node
    end
  end
end
