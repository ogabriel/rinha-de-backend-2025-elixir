defmodule Rinha.Router do
  use Plug.Router

  # if Code.ensure_loaded?(Mix) && Mix.env() == :dev do
  #   plug(PlugCodeReloader)
  #   plug(Plug.Logger)
  # end

  plug(:match)
  plug(:dispatch)

  post "/payments" do
    {:ok, body, _} = Plug.Conn.read_body(conn)

    Task.Supervisor.start_child(Rinha.TaskSupervisor, fn ->
      {body, :ok, _} =
        JSON.decode(body, {:requestedAt, DateTime.utc_now()},
          object_push: fn key, value, acc -> [{String.to_atom(key), value} | acc] end,
          object_finish: fn acc, old_acc -> {Map.new([old_acc | acc]), :ok} end
          # float: & &1
        )

      processor = Rinha.Processor.Client.call(JSON.encode_to_iodata!(body))

      body = Map.put(body, :processor, processor)

      Rinha.Payments.insert(body)
    end)

    send_resp(conn, 200, "")
  end

  get "/payments-summary" do
    {from, to} = parse_dates(Plug.Conn.Query.decode(conn.query_string))

    %{
      default_requests: default_requests,
      default_amount: default_amount,
      fallback_requests: fallback_requests,
      fallback_amount: fallback_amount
    } = Rinha.Payments.summary(from, to)

    [node] = Node.list()

    %{
      default_requests: default_requests_node,
      default_amount: default_amount_node,
      fallback_requests: fallback_requests_node,
      fallback_amount: fallback_amount_node
    } = :erpc.call(node, Rinha.Payments, :summary, [from, to], :infinity)

    result = %{
      default: %{
        totalRequests: default_requests + default_requests_node,
        totalAmount: (default_amount + default_amount_node) / 100
      },
      fallback: %{
        totalRequests: fallback_requests + fallback_requests_node,
        totalAmount: (fallback_amount + fallback_amount_node) / 100
      }
    }

    send_resp(conn, 200, JSON.encode_to_iodata!(result))
  end

  defp parse_dates(decoded) do
    {from, to} =
      case decoded do
        %{"from" => from, "to" => to} -> {from, to}
        %{"from" => from} -> {from, nil}
        %{"to" => to} -> {nil, to}
      end

    {parse(from), parse(to)}
  end

  defp parse(nil), do: nil
  defp parse(""), do: nil
  defp parse(date), do: DateTime.from_iso8601(date) |> elem(1) |> DateTime.to_unix(:millisecond)

  post "/purge-payments" do
    Rinha.Payments.delete_all()

    send_resp(conn, 200, "")
  end

  get "/up" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "")
  end
end
