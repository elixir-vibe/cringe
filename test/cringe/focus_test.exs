defmodule Cringe.FocusTest do
  use ExUnit.Case, async: true

  alias Cringe.Focus

  test "tracks current focus" do
    focus = Focus.new([:search, :results])

    assert Focus.current(focus) == :search
    assert Focus.focused?(focus, :search)
    refute Focus.focused?(focus, :results)
  end

  test "moves through a focus ring" do
    focus = Focus.new([:search, :results], current: :results)

    assert focus |> Focus.next() |> Focus.current() == :search
    assert focus |> Focus.previous() |> Focus.current() == :search
  end

  test "handles empty focus rings" do
    focus = Focus.new([])

    assert Focus.current(focus) == nil
    assert Focus.next(focus) == focus
    assert Focus.previous(focus) == focus
  end
end
