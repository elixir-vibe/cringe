defmodule Cringe.Document do
  @moduledoc """
  Terminal document helpers.
  """

  @type t :: Cringe.Document.Text.t() | Cringe.Document.Stack.t() | Cringe.Document.Box.t()
end
