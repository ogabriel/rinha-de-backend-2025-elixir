defmodule Rinha.Processor.Client do
  @default_host Application.compile_env(:rinha, :default_host)
  @default_port Application.compile_env(:rinha, :default_port)
  @payments_path "/payments"
  @service_health_path "/payments/service-health"
  @get "GET"
  @post "POST"

  @headers [
    {"Content-Type", "application/json"}
  ]

  def call(payload) do
    call(Rinha.Processor.Health.get_best_processor(), payload)
  end

  defp call(:wait, payload) do
    :timer.sleep(1000)
    call(Rinha.Processor.Health.get_best_processor(), payload)
  end

  defp call(:default, payload) do
    case %Finch.Request{
           scheme: :http,
           host: @default_host,
           port: @default_port,
           method: @post,
           path: @payments_path,
           headers: @headers,
           query: nil,
           body: payload
         }
         |> Finch.request(Rinha.FinchPayments) do
      {:ok, %{status: 200}} ->
        :default

      {:ok, %{status: 422}} ->
        :default

      _ ->
        call(Rinha.Processor.Health.get_best_processor(), payload)
    end
  end

  def default_health do
    case %Finch.Request{
           scheme: :http,
           host: @default_host,
           port: @default_port,
           method: @get,
           path: @service_health_path,
           headers: @headers,
           query: nil,
           body: nil
         }
         |> Finch.request(Rinha.FinchPaymentsHealth) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_payload!(body)}

      {:ok, %{status: 429}} ->
        :timer.sleep(100)
        default_health()

      _ ->
        :error
    end
  end

  defp parse_payload!(body) do
    case JSON.decode(body, :ok, object_push: fn key, value, acc -> [{String.to_atom(key), value} | acc] end) do
      {parsed, :ok, _} -> parsed
    end
  end
end
