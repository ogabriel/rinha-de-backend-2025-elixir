defmodule Rinha.Payments do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    :ets.new(__MODULE__, [
      :set,
      :public,
      :named_table,
      write_concurrency: true,
      read_concurrency: true,
      decentralized_counters: true
    ])

    {:ok, nil}
  end

  def insert(correlation_id, amount, processor, requested_at) do
    :ets.insert(__MODULE__, {correlation_id, amount, processor, requested_at})
  end

  def summary(from, to) do
    __MODULE__
    |> :ets.select([
      {
        {:"$1", :"$2", :"$3", :"$4"},
        build_match(from, to),
        [{{:"$3", :"$2"}}]
      }
    ])
    |> parse_summary()
  end

  defp build_match(nil, nil) do
    []
  end

  defp build_match(from, nil) do
    [{:>=, :"$4", from}]
  end

  defp build_match(nil, to) do
    [{:"=<", :"$4", to}]
  end

  defp build_match(from, to) do
    [{:andalso, {:>=, :"$4", from}, {:"=<", :"$4", to}}]
  end

  defp parse_summary(result) do
    result
    |> Enum.reduce(%{default_requests: 0, default_amount: 0, fallback_requests: 0, fallback_amount: 0}, fn
      {:default, amount}, %{default_requests: default_requests, default_amount: default_amount} = acc ->
        %{acc | default_requests: default_requests + 1, default_amount: default_amount + amount}

      {:fallback, amount}, %{fallback_requests: fallback_requests, fallback_amount: fallback_amount} = acc ->
        %{acc | fallback_requests: fallback_requests + 1, fallback_amount: fallback_amount + amount}
    end)
  end

  def delete_all do
    :ets.delete_all_objects(__MODULE__)
  end
end
