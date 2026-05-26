defmodule Cringe.App do
  @moduledoc """
  Behaviour and macro for Cringe applications.
  """

  @callback init(keyword()) :: {:ok, term()} | {:stop, term()}
  @callback handle_event(Cringe.Event.t(), term()) :: {:noreply, term()} | {:stop, term()}
  @callback render(term()) :: Cringe.Document.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Cringe.App

      import Cringe

      @impl Cringe.App
      def handle_event(_event, state), do: {:noreply, state}

      defoverridable handle_event: 2
    end
  end
end
