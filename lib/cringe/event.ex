defmodule Cringe.Event do
  @moduledoc """
  Semantic runtime input events.
  """

  alias Cringe.Event.{Key, Resize, Text, Tick}

  @type t ::
          Cringe.Event.Key.t()
          | Cringe.Event.Text.t()
          | Cringe.Event.Resize.t()
          | Cringe.Event.Tick.t()

  @spec key(atom(), keyword()) :: Key.t()
  def key(key, opts \\ []), do: Key.new(key, opts)

  @spec text(String.t()) :: Text.t()
  def text(text), do: Text.new(text)

  @spec resize(pos_integer(), pos_integer()) :: Resize.t()
  def resize(width, height), do: Resize.new(width, height)

  @spec tick(term()) :: Tick.t()
  def tick(id), do: Tick.new(id)
end
