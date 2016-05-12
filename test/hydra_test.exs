defmodule HydraTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  defmacro capture_shutdown(args) do
    quote do
      try do
        unquote args[:do]
      catch
        :exit, :shutdown -> true
      end
    end
  end

  test "invalid URLs" do
    urls = [
      "//localhost:4000",
      "http//localhost:4000",
      "http://localhost:"
    ]

    for url <- urls do
      output = capture_io(fn ->
        capture_shutdown do
          Hydra.CLI.main [url]
        end
      end)

      assert output == "Invalid URL: #{url}\n"
    end
  end
end
