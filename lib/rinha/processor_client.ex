defmodule Rinha.ProcessorClient do
  @default "#{Application.compile_env(:rinha, :default_processor)}/payments"
  @fallback "#{Application.compile_env(:rinha, :fallback_processor)}/payments"
  @headers [
    {"Content-Type", "application/json"}
  ]

  def call(payload) do
    url =
      case Rinha.Processor.Health.get_best_processor() do
        :default ->
          @default

        :fallback ->
          @fallback
      end

    case Finch.build(:post, url, @headers, payload)
         |> Finch.request(Rinha.Finch) do
      {:ok, %{status: 200}} -> :ok
      _ -> call(payload)
    end
  end

  def default_health do
    case Finch.build(:get, "#{@default}/service-health")
         |> Finch.request(Rinha.Finch) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_payload!(body)}

      {:ok, %{status: 429}} ->
        # TODO: maybe put sleep
        default_health()

      _ ->
        :error
    end
  end

  def fallback_health do
    case Finch.build(:get, "#{@fallback}/service-health")
         |> Finch.request(Rinha.Finch) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_payload!(body)}

      {:ok, %{status: 429}} ->
        # TODO: maybe put sleep
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
