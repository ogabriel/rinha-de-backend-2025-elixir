defmodule Rinha.Repo do
  use Ecto.Repo,
    otp_app: :rinha,
    adapter: Ecto.Adapters.Postgres
end
