defmodule Rinha.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    connect_to_node()

    children = [
      Rinha.Payments,
      Rinha.Processor.Health,
      {Task.Supervisor, name: Rinha.TaskSupervisor},
      {Finch,
       name: Rinha.FinchPayments,
       pools: %{
         :default => [size: 200, count: 1, conn_max_idle_time: 10_000]
       }},
      {Finch,
       name: Rinha.FinchPaymentsHealth,
       pools: %{
         Application.get_env(:rinha, :default_processor) => [size: 1, count: 1],
         Application.get_env(:rinha, :fallback_processor) => [size: 1, count: 1]
       }},
      {Bandit, plug: Rinha.Router, port: 9999}
    ]

    children = add_code_reloader(children)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rinha.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp add_code_reloader(children) do
    if Code.ensure_loaded?(Mix) && Mix.env() == :dev do
      [PlugCodeReloader.Server | children]
    else
      children
    end
  end

  defp connect_to_node() do
    if !Code.ensure_loaded?(Mix) && node() == :"app@app1.com" do
      case Node.connect(:"app@app2.com") do
        true ->
          :ok

        _ ->
          :timer.sleep(1000)
          connect_to_node()
      end
    end
  end
end
