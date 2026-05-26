Code.require_file("support/documents.exs", __DIR__)
import Cringe
alias Cringe.Bench.Documents

Benchee.run(
  %{
    "text render" => fn -> Cringe.render(text("hello"), width: 80, height: 24) end,
    "box render" => fn -> Cringe.render(box(text("hello"), padding: 1), width: 80, height: 24) end,
    "dashboard render" => fn -> Cringe.render(Documents.dashboard(), width: 80, height: 24, ansi: true) end,
    "widgets render" => fn -> Cringe.render(Documents.widgets(), width: 80, height: 24, ansi: true) end,
    "dashboard frame" => fn -> Cringe.frame(Documents.dashboard(), width: 80, height: 24, ansi: true) end
  },
  time: 1,
  memory_time: 0.2
)
