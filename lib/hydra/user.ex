defmodule Hydra.User do
  use Timex

  ## Public API
  def start(link) do
    link |> request
  end

  def request(link) do
    {latency, _} = :timer.tc(fn ->
      :ibrowse.send_req(String.to_char_list(link), [], :get)
    end)

    {_, time, _} = Time.now
    Hydra.Stats.insert({latency, time})

    request(link)
  end
end
