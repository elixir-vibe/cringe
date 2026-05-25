import Cringe

row(
  [
    box(text("nav", align: :center), width: 12, padding: 1),
    box(text("content", align: :center), grow: 1, padding: 1)
  ],
  gap: 2,
  width: 48
)
|> render()
|> IO.puts()
