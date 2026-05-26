defmodule Cringe.Case do
  @moduledoc """
  Convenience imports for Cringe ExUnit tests.

  Use this after `use ExUnit.Case`:

      use ExUnit.Case, async: true
      use Cringe.Case

  """

  defmacro __using__(_opts) do
    quote do
      import Cringe
      import Cringe.Assertions
    end
  end
end
