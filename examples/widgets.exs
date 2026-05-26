use Cringe

box padding: 1 do
  column gap: 1 do
    spinner(frame: 2, label: "Loading")
    progress(value: 0.42, width: 16, label: "Build")
    input(value: "cringe", focused: true, width: 24)
    select(options: ["Dashboard", "Logs", "Settings"], selected: 1)
  end
end
|> render()
|> IO.puts()
