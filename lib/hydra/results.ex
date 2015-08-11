defmodule Hydra.Results do
  def summarize(%{time: time}) do
    IO.puts "Collecting Stats...\n"

    reqs = Hydra.Stats.all

    reqs_latency = Enum.map(reqs, fn ({latency, _, _}) -> latency end)
    data_received = Stream.map(reqs, fn ({_, _, data}) -> data end) |> Enum.sum

    reqs_latency
    |> average_response
    |> standard_deviation
    |> min_response
    |> max_response
    |> reqs_secs(time)
    |> socket_errors

    status_codes(reqs)

    IO.puts "\n  #{length(reqs_latency)} requests in #{time}s, #{bytes_to_mb(data_received)} read\n"
  end

  defp status_codes(reqs) do
    codes_map =
    Enum.map(reqs, fn ({_, status_code, _}) -> status_code end)
    |> Enum.reduce(Map.new, fn (code, map) ->
        case code do
          200 -> map
          _ -> Map.update(map, code, 0, &(&1 + 1))
        end
      end)

    if Map.keys(codes_map) |> length > 0, do:
      IO.puts "  Non 200 responses: "
      codes_map |> Enum.each(fn({k, v}) -> IO.puts "    #{k} => #{v}" end)
  end

  defp average_response(reqs_latency) do
    avg = (reqs_latency |> Enum.sum) / (reqs_latency |> length)
    IO.puts "  Latency:     #{formatted_diff(avg)} (Avg)"
    reqs_latency
  end

  defp standard_deviation(reqs_latency) do
    stdev = reqs_latency |> Statistics.stdev
    IO.puts "  Stdev:       #{formatted_diff(stdev)}"
    reqs_latency
  end

  defp min_response(reqs_latency) do
    min = reqs_latency |> Enum.min
    IO.puts "  Min:         #{formatted_diff(min)}"
    reqs_latency
  end

  defp max_response(reqs_latency) do
    max = reqs_latency |> Enum.max
    IO.puts "  Max:         #{formatted_diff(max)}"
    reqs_latency
  end

  defp reqs_secs(reqs_latency, time) do
    IO.puts "  Reqs/Sec:    #{length(reqs_latency)/time}\n"
  end

  defp socket_errors(_) do
    errors =
      Hydra.Errors.all |> Enum.reduce(%{}, fn (error, acc) ->
        Map.update(acc, error, 1, &(&1 + 1))
      end)

    case errors |> Map.keys |> length do
      0 -> :ok
      _ ->
        closed     = Map.get(errors, :closed, 0)
        connect    = Map.get(errors, :connect_timeout, 0)
        timeout    = Map.get(errors, :timeout, 0)
        conn_reset = Map.get(errors, :econnreset, 0)

        IO.puts "  Socket errors: closed: #{closed}, connect: #{connect}, timeout: #{timeout}, conn. reset: #{conn_reset}"
    end
  end
  
  defp formatted_diff(diff) when diff > 1000 do
    time = diff/1000
    cond do
      is_float(time) ->
        [time |> Float.to_string(decimals: 2), "ms"]
      is_integer(time) ->
        [time |> Integer.to_string, "ms"]
    end
  end

  defp formatted_diff(diff) when is_float(diff), do: [diff |> Float.to_string(decimals: 2), "µs"]
  defp formatted_diff(diff) when is_integer(diff), do: [diff |> Integer.to_string, "µs"]

  defp bytes_to_mb(bytes) do
    mb = 1024.0 * 1024.0
    Float.to_string(bytes / mb, [decimals: 2, compact: true]) <> "MB"
  end
end
