defmodule Cringe.ANSI do
  @moduledoc false

  @colors %{
    black: 30,
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37,
    default: 39
  }

  @spec apply(String.t(), keyword(), boolean()) :: String.t()
  def apply(text, _opts, false), do: text

  def apply(text, opts, true) do
    codes = codes(opts)

    case codes do
      [] -> text
      _ -> ["\e[", Enum.join(codes, ";"), "m", text, "\e[0m"] |> IO.iodata_to_binary()
    end
  end

  defp codes(opts) do
    []
    |> maybe_code(Keyword.get(opts, :bold), "1")
    |> maybe_code(Keyword.get(opts, :italic), "3")
    |> maybe_code(Keyword.get(opts, :underline), "4")
    |> color_code(Keyword.get(opts, :color))
  end

  defp maybe_code(codes, true, code), do: [code | codes]
  defp maybe_code(codes, _enabled, _code), do: codes

  defp color_code(codes, nil), do: Enum.reverse(codes)

  defp color_code(codes, color) do
    color_code = Map.get(@colors, color)
    if color_code, do: Enum.reverse([to_string(color_code) | codes]), else: Enum.reverse(codes)
  end
end
