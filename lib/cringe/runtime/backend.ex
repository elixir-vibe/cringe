defmodule Cringe.Runtime.Backend do
  @moduledoc """
  Behaviour for runtime output backends.
  """

  @callback init(keyword()) :: {:ok, term()} | {:error, term()}
  @callback render(IO.chardata(), term()) :: {:ok, term()} | {:error, term()}
  @callback stop(term()) :: :ok
end
