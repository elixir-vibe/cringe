Cringe.column(
  [
    Cringe.box(Cringe.text("Cringe"), padding: 1),
    Cringe.row(
      [
        Cringe.box(Cringe.text("runtime\nready"), padding: 1),
        Cringe.box(Cringe.text("tests\ngreen"), padding: 1)
      ],
      gap: 2
    )
  ],
  gap: 1
)
|> Cringe.render(width: 80)
|> IO.puts()
