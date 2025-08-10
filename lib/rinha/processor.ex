defmodule Rinha.Processor do
  def call(requested_at, body) do
    {body, :ok, _} =
      JSON.decode(body, {:requestedAt, requested_at},
        object_push: fn key, value, acc -> [{String.to_atom(key), value} | acc] end,
        object_finish: fn acc, old_acc -> {Map.new([old_acc | acc]), :ok} end,
        float: & &1
      )

    processor = Rinha.Processor.Client.call(JSON.encode_to_iodata!(body))

    body = Map.put(body, :processor, processor)

    Rinha.Payments.insert(body)
  end
end
