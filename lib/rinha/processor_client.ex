defmodule Rinha.ProcessorClient do
  @default "#{Application.compile_env(:rinha, :default_processor)}/payments"
  @fallback "#{Application.compile_env(:rinha, :fallback_processor)}/payments"
  @headers [
    {"Content-Type", "application/json"}
  ]

  def call(payload) do
    payload = JSON.encode_to_iodata!(payload)

    call_api(payload)
  end

  def call_api(payload) do
    case Finch.build(:post, @default, @headers, payload)
         |> Finch.request(Rinha.Finch) do
      {:ok, %{status: 200}} -> :ok
      _ -> call_api(payload)
    end
  end

  def default_health do
    case Finch.build(:get, "#{@default}/service-health")
         |> Finch.request(Rinha.Finch) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, JSON.decode!(body)}

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
        {:ok, JSON.decode!(body)}

      {:ok, %{status: 429}} ->
        # TODO: maybe put sleep
        default_health()

      _ ->
        :error
    end
  end
end
