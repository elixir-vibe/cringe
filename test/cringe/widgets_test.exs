defmodule Cringe.WidgetsTest do
  use ExUnit.Case, async: true

  import Cringe
  import Cringe.Test, only: [assert_render: 2]

  test "renders progress bars" do
    assert_render(progress(value: 0.5, width: 4), """
    [██░░]
    """)
  end

  test "renders spinners" do
    assert render(spinner(frame: 1, label: "Loading")) == "⠙ Loading"
  end

  test "renders input fields" do
    assert render(input(value: "abc", focused: true, width: 7)) == "> abc▌ "
  end

  test "renders select lists" do
    assert_render(select(options: ["one", "two"], selected: 1), """
      one
    › two
    """)
  end
end
