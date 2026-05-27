defmodule Cringe.Overlay.Layer do
  @moduledoc """
  A positioned overlay document.
  """

  @anchors [:center, :top, :bottom, :top_left, :top_right, :bottom_left, :bottom_right]

  @enforce_keys [:id, :document]
  defstruct [
    :id,
    :document,
    anchor: :center,
    x: nil,
    y: nil,
    width: nil,
    height: nil,
    margin: 0,
    capture?: true
  ]

  @type anchor :: :center | :top | :bottom | :top_left | :top_right | :bottom_left | :bottom_right
  @type t :: %__MODULE__{
          id: term(),
          document: Cringe.Document.t(),
          anchor: anchor(),
          x: non_neg_integer() | nil,
          y: non_neg_integer() | nil,
          width: pos_integer() | nil,
          height: pos_integer() | nil,
          margin: non_neg_integer(),
          capture?: boolean()
        }

  @spec new(term(), Cringe.Document.t(), keyword()) :: t()
  def new(id, document, opts \\ []) do
    anchor = Keyword.get(opts, :anchor, :center)

    if anchor not in @anchors do
      raise ArgumentError, "unknown overlay anchor #{inspect(anchor)}"
    end

    %__MODULE__{
      id: id,
      document: document,
      anchor: anchor,
      x: Keyword.get(opts, :x),
      y: Keyword.get(opts, :y),
      width: Keyword.get(opts, :width),
      height: Keyword.get(opts, :height),
      margin: Keyword.get(opts, :margin, 0),
      capture?: Keyword.get(opts, :capture?, true)
    }
  end
end
