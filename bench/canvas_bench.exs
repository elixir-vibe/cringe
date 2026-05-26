Code.require_file("support/documents.exs", __DIR__)
alias Cringe.Bench.Documents
alias Cringe.Canvas

lines = Documents.lines(24)

Benchee.run(
  %{
    "new canvas" => fn -> Canvas.new(80, 24) end,
    "put text" => fn -> Canvas.new(80, 24) |> Canvas.put(10, 5, "hello") end,
    "put block" => fn -> Canvas.new(80, 24) |> Canvas.put_block(0, 0, lines) end
  },
  time: 1,
  memory_time: 0.2
)
