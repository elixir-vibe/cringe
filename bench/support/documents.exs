defmodule Cringe.Bench.Documents do
  import Cringe

  def dashboard do
    box padding: 1 do
      column gap: 1 do
        text("Cringe Dashboard", color: :green, bold: true)

        row gap: 2, width: 76 do
          box(text("CPU\n42%"), padding: 1, grow: 1)
          box(text("Memory\n512MB"), padding: 1, grow: 1)
          box(text("Jobs\n17"), padding: 1, grow: 1)
        end

        text(log_lines(), height: 8)
      end
    end
  end

  def widgets do
    box padding: 1 do
      column gap: 1 do
        spinner(frame: 4, label: "Loading")
        progress(value: 0.42, width: 24, label: "Build")
        input(value: "cringe", focused: true, width: 32)
        select(options: ["Dashboard", "Logs", "Settings", "Help"], selected: 2)
      end
    end
  end

  def lines(count \\ 24) do
    Enum.map(1..count, &"line #{&1}: #{String.duplicate("x", rem(&1, 12) + 4)}")
  end

  defp log_lines do
    1..12
    |> Enum.map(&"[info] rendered frame #{&1}")
    |> Enum.join("\n")
  end
end
