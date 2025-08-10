defmodule Rinha.Processor.Client do
  @default_host Application.compile_env(:rinha, :default_host)
  @default_port Application.compile_env(:rinha, :default_port)
  @fallback_host Application.compile_env(:rinha, :fallback_host)
  @fallback_port Application.compile_env(:rinha, :fallback_port)
  @payments_path "/payments"
  @service_health_path "/payments/service-health"
  @get "GET"
  @post "POST"

  @headers [
    {"Content-Type", "application/json"}
  ]

  def call(payload) do
    processor = Rinha.Processor.Health.get_best_processor()

    {host, port} =
      case processor do
        :default -> {@default_host, @default_port}
        :fallback -> {@fallback_host, @fallback_port}
      end

    case %Finch.Request{
           scheme: :http,
           host: host,
           port: port,
           method: @post,
           path: @payments_path,
           headers: @headers,
           query: nil,
           body: payload
         }
         |> Finch.request(Rinha.FinchPayments, pool_timeout: 10_000) do
      {:ok, %{status: 200}} ->
        processor

      {:ok, %{status: 422}} ->
        processor

      _ ->
        call(payload)
    end
  end

  def default_health do
    case %Finch.Request{
           scheme: :http,
           host: @default_host,
           port: @default_port,
           method: "GET",
           path: @service_health_path,
           headers: @headers,
           query: nil,
           body: nil
         }
         |> Finch.request(Rinha.FinchPaymentsHealth) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_payload!(body)}

      {:ok, %{status: 429}} ->
        default_health()

      _ ->
        :error
    end
  end

  def fallback_health do
    case %Finch.Request{
           scheme: :http,
           host: @fallback_host,
           port: @fallback_port,
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
        fallback_health()

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
