defmodule Rinha.Router do
  use Plug.Router

  if Mix.env() == :dev do
    plug(PlugCodeReloader)
    plug(Plug.Logger)
  end

  plug(:match)
  plug(:dispatch)

  post "/payments" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    Task.async(fn ->
      {:ok, body} = JSON.decode(body)

      body = Map.put(body, "requestedAt", DateTime.utc_now() |> DateTime.to_iso8601())

      Rinha.ProcessorClient.call(body)
    end)

    send_resp(conn, 200, "")
  end

  get "payments-summary" do
    result = %{
      default: %{
        totalRequests: 43236,
        totalAmount: 415_542_345.98
      },
      fallback: %{
        totalRequests: 423_545,
        totalAmount: 329_347.34
      }
    }

    send_resp(conn, 200, JSON.encode_to_iodata!(result))
  end

  get "/up" do
    send_resp(conn, 200, "a")
  end

  match _ do
    send_resp(conn, 404, "")
  end
end
