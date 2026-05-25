import Cringe

column(
  [
    box(text("Cringe"), padding: 1),
    row(
      [
        box(text("runtime\nready"), padding: 1),
        box(text("tests\ngreen"), padding: 1)
      ],
      gap: 2
    )
  ],
  gap: 1
)
|> render(width: 80)
|> IO.puts()
