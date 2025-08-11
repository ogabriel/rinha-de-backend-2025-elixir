defmodule Rinha.Processor.Health do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    :ets.new(__MODULE__, [:set, :public, :named_table, read_concurrency: true, decentralized_counters: true])

    if !Code.ensure_loaded?(Mix) && node() == :"app@app1.com" do
      Process.send_after(self(), :check_health, 1_000)
    end

    {:ok, nil}
  end

  def handle_info(:check_health, state) do
    [default_result, fallback_result] =
      Task.await_many(
        [
          Task.async(fn -> Rinha.Processor.Client.default_health() end),
          Task.async(fn -> Rinha.Processor.Client.fallback_health() end)
        ],
        :infinity
      )

    processor = parse_best_processor(default_result, fallback_result)

    set_best_processor(processor)

    if !Code.ensure_loaded?(Mix) && node() == :"app@app1.com" do
      [node] = Node.list()
      :erpc.call(node, Rinha.Processor.Health, :set_best_processor, [processor], :infinity)
    end

    Process.send_after(self(), :check_health, 4_900)

    {:noreply, state}
  end

  def parse_best_processor(:error, :error), do: :failing
  def parse_best_processor({:ok, %{failing: false}}, :error), do: :default

  def parse_best_processor(
        {:ok, %{failing: failing_default, minResponseTime: response_default}},
        {:ok, %{failing: failing_fallback, minResponseTime: response_fallback}}
      ) do
    cond do
      failing_default && failing_fallback -> :failing
      !failing_default && failing_fallback -> :default
      failing_default && !failing_fallback -> :fallback
      (response_fallback + 100) * 1.5 < response_default -> :fallback
      true -> :default
    end
  end

  def set_best_processor(processor) do
    :ets.insert(__MODULE__, {:processor, processor})
  end

  def get_best_processor() do
    case :ets.lookup(__MODULE__, :processor) do
      processor: processor -> processor
      _ -> :default
    end
  end
end
