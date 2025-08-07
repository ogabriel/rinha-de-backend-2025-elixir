defmodule Rinha.Processor.Health do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    :ets.new(__MODULE__, [:set, :public, :named_table])

    Process.send_after(self(), :check_health, 1_000)

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

    default_result
    |> parse_best_processor(fallback_result)
    |> set_best_processor()

    Process.send_after(self(), :check_health, 5_000)

    {:noreply, state}
  end

  def parse_best_processor(result) do
    case result do
      [{:default, :ok}, {:fallback, :ok}] -> :default
      [{:default, :ok}, {:fallback, :error}] -> :default
      [{:default, :error}, {:fallback, :ok}] -> :fallback
      [{:default, :error}, {:fallback, :error}] -> :fallback
    end
  end

  def parse_best_processor(:error, :error), do: :default
  def parse_best_processor({:ok, _}, :error), do: :default
  def parse_best_processor(:error, {:ok, _}), do: :fallback
  def parse_best_processor({:ok, _}, {:ok, %{failing: true}}), do: :default
  def parse_best_processor({:ok, %{failing: true}}, {:ok, _}), do: :fallback

  def parse_best_processor({:ok, %{minResponseTime: default}}, {:ok, %{minResponseTime: fallback}}) do
    if default <= fallback + 100 do
      :default
    else
      :fallback
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
