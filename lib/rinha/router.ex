defmodule Rinha.Router do
  use Plug.Router

  if Mix.env() == :dev do
    plug(PlugCodeReloader)
    plug(Plug.Logger)
  end

  plug(:match)
  plug(:dispatch)

  post "/payments" do
  end

  get "payments-summary" do
  end

  get "/up" do
    send_resp(conn, 200, "a")
  end

  match _ do
    send_resp(conn, 404, "")
  end
end
