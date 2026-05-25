use Cringe

box padding: 1 do
  column gap: 1 do
    text("Cringe", color: :green, bold: true)
    text("Terminal UI for the BEAM")
  end
end
|> render(ansi: true)
|> IO.puts()
