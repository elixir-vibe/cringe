Code.require_file("support/documents.exs", __DIR__)
alias Cringe.Bench.Documents
alias Cringe.Painter

frame1 = Cringe.frame(Documents.dashboard(), width: 80, height: 24, ansi: true)
frame2 = Cringe.frame(Documents.widgets(), width: 80, height: 24, ansi: true)
{_output, warm_painter} = Painter.render(Painter.new(80, 24), frame1)

Benchee.run(
  %{
    "first paint" => fn -> Painter.render(Painter.new(80, 24), frame1) end,
    "diff paint" => fn -> Painter.render(warm_painter, frame2) end,
    "unchanged paint" => fn -> Painter.render(warm_painter, frame1) end
  },
  time: 1,
  memory_time: 0.2
)
