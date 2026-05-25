defmodule Cringe.DSLTest do
  use ExUnit.Case, async: true

  use Cringe
  import Cringe.Test, only: [assert_render: 2]

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
