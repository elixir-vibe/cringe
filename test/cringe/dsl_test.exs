defmodule Cringe.DSLTest do
  use ExUnit.Case, async: true

  use Cringe
  use Cringe.Case

  test "supports block-oriented document syntax" do
    document =
      box padding: 1 do
        column gap: 1 do
          text("Cringe")
          text("Terminal UI")
        end
      end

    assert_render(document, """
    ╭─────────────╮
    │             │
    │ Cringe      │
    │             │
    │ Terminal UI │
    │             │
    ╰─────────────╯
    """)
  end
end
