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
    set_best_processor_parallel(:wait)

    default_result = Rinha.Processor.Client.default_health()

    processor = parse_best_processor(default_result)

    set_best_processor_parallel(processor)

    Process.send_after(self(), :check_health, 4_900)

    {:noreply, state}
  end

  def parse_best_processor(:error), do: :wait
  def parse_best_processor({:ok, %{failing: false}}), do: :default
  def parse_best_processor({:ok, %{failing: true}}), do: :wait

  def set_best_processor_parallel(processor) do
    Task.await_many(
      [
        Task.async(fn -> set_best_processor(processor) end),
        Task.async(fn ->
          if !Code.ensure_loaded?(Mix) && node() == :"app@app1.com" do
            [node] = Node.list()
            :erpc.call(node, Rinha.Processor.Health, :set_best_processor, [processor], :infinity)
          end
        end)
      ],
      :infinity
    )
  end

  def set_best_processor(processor) do
    :ets.insert(__MODULE__, {:processor, processor})
  end

  def get_best_processor() do
    :ets.lookup_element(__MODULE__, :processor, 2, :wait)
  end
end
