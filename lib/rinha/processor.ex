defmodule Rinha.Processor do
  def call(body) do
    requested_at = DateTime.utc_now() |> DateTime.truncate(:millisecond)

    {body, :ok, _} =
      JSON.decode(body, {:requestedAt, requested_at},
        object_push: fn key, value, acc -> [{String.to_atom(key), value} | acc] end,
        object_finish: fn acc, old_acc -> {Map.new([old_acc | acc]), :ok} end,
        float: & &1
      )

    correlation_id = body.correlationId
    amount = parse_amount(body.amount)
    requested_at = parse_requested_at(body.requestedAt)

    processor = Rinha.Processor.Client.call(JSON.encode_to_iodata!(body))

    Rinha.Payments.insert({correlation_id, processor, amount, requested_at})
  end

  defp parse_amount(binary) do
    charlist = :erlang.binary_to_list(binary)

    intlist =
      case :lists.splitwith(&(&1 != ?.), charlist) do
        {int, [?., rest]} -> int ++ [rest, ?0]
        {int, [?. | rest]} -> int ++ rest
      end

    List.to_integer(intlist)
  end

  defp parse_requested_at(requested_at) do
    DateTime.to_unix(requested_at, :millisecond)
  end
end
