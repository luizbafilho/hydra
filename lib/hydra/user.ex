defmodule Hydra.User do
  use Timex

  ## Public API
  def start(link) do
    link |> request
  end

  def request(link) do
    {latency, _} = :timer.tc(fn ->
      {ok, status_code, headers, ref} = :hackney.request(:get, String.to_char_list(link), [], '', [])
      :hackney.body(ref)
    end)

    {_, time, _} = Time.now
    Hydra.Stats.insert({latency, time})

    request(link)
  end
end
