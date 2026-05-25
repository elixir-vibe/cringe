defmodule Cringe.Runtime.Backend do
  @moduledoc """
  Behaviour for runtime output backends.
  """

  @callback init(keyword()) :: {:ok, term()} | {:error, term()}
  @callback render(String.t(), term()) :: {:ok, term()} | {:error, term()}
  @callback stop(term()) :: :ok
end
