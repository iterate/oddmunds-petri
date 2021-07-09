defmodule PetrixWeb.PageLive do
  use PetrixWeb, :live_view

  @tick 50
  @tick_variance -20..50

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, @tick)
    seed_algo = :normal
    nodes = make_nodes(10, seed_algo)
    {:ok, assign(socket, query: "", results: %{}, nodes: nodes, seed_algo: seed_algo)}
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @tick + Enum.random(@tick_variance))
    {:noreply, update(socket, :nodes, &alter_nodes/1)}
  end

  @impl true
  def handle_event("reseed", _params, socket) do
    seed_algo = socket.assigns.seed_algo
    {:noreply, assign(socket, :nodes, make_nodes(10, seed_algo))}
  end

  def handle_event("set_seed_algo", %{"value" => value}, socket) do
    value =
      case value do
        "normal" -> :normal
        "random" -> :random
      end

    {:noreply, assign(socket, :seed_algo, value)}
  end

  defp make_nodes(n, :random) do
    range = 0..700

    for _ <- 0..n do
      %{x: Enum.random(range), y: Enum.random(range)}
    end
  end

  defp make_nodes(n, :normal) do
    range = 0..700

    for _ <- 0..n do
      %{x: dist(range), y: dist(range)}
    end
  end

  defp make_nodes2(n) do
    range = 0..700

    {nodes, _} =
      0..n
      |> Enum.map_reduce(nil, &make_nodes_reducer/2)

    nodes
  end

  defp make_nodes_reducer(x, acc) do
    case {x, acc} do
      {_, nil} ->
        node = %{x: 500, y: 500}
        {node, node}

      {_, prev_node} ->
        range = -100..100
        node = %{x: prev_node.x + Enum.random(range), y: prev_node.y + Enum.random(range)}
        {node, node}
    end
  end

  defp dist(range) do
    (Enum.random(range) + Enum.random(range))
    |> div(2)
    |> floor()
  end

  defp anti_dist(range) do
    max = Enum.max(range)

    moved = dist(range) + max

    anti = rem(moved, max)

    anti
  end

  defp alter_nodes(nodes) do
    Enum.map(nodes, &alter_node/1)
  end

  defp alter_nodes2(nodes) do
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
