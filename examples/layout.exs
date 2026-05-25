Cringe.row(
  [
    Cringe.box(Cringe.text("nav", align: :center), width: 12, padding: 1),
    Cringe.box(Cringe.text("content", align: :center), grow: 1, padding: 1)
  ],
  gap: 2,
  width: 48
)
|> Cringe.render()
|> IO.puts()
