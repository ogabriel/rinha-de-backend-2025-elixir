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
    # TODO: improve parsing of json
    # JSON.decode("{\"a\": 1.2}", %{b: 1}, object_push: fn key, value, acc -> [{String.to_atom(key), value} | acc] end, float: & &1)

    Task.async(fn ->
      {:ok, body} = JSON.decode(body)

      body = Map.put(body, "requestedAt", DateTime.utc_now() |> DateTime.to_iso8601())

      processor = Rinha.ProcessorClient.call(JSON.encode_to_iodata!(body))

      Rinha.Payments.insert(%{
        correlationId: body["correlationId"],
        # TOOD: fix decimal
        amount: body["amount"],
        processor: processor,
        requestedAt: body["requestedAt"]
      })
    end)

    send_resp(conn, 200, "")
  end

  get "/payments-summary" do
    # TODO: fix date format
    %{"from" => from, "to" => to} = Plug.Conn.Query.decode(conn.query_string)

    %{
      default_requests: default_requests,
      default_amount: default_amount,
      fallback_requests: fallback_requests,
      fallback_amount: fallback_amount
    } =
      Rinha.Payments.summary(from, to)

    result = %{
      default: %{
        totalRequests: default_requests,
        totalAmount: default_amount
      },
      fallback: %{
        totalRequests: fallback_requests,
        totalAmount: fallback_amount
      }
    }

    send_resp(conn, 200, JSON.encode_to_iodata!(result))
  end

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
