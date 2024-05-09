defmodule Exercise.Services.CurrencyConverter do
  @moduledoc """
  Module implementing the currency conversion service

  Note: The current implementation will not contact any external service
  and will use fixed conversion rates that will most likely not be the correct ones.
  """
  @type currency() :: String.t()

  @doc """
  Converts a currency by `amount` given three-letter currency code `from` and `to`.
  Returns an :ok and converted currency in float type, else an :error tuple when currency is not supported.

  ## Examples
    iex> CurrencyConverter.convert("USD", "EUR", 1.0)
    {:ok, 0.8442}
  """
  @spec convert(currency(), currency(), float()) :: {:ok, float()} | {:error, String.t()}
  def convert(from, to, amount) do
    case rates()[from <> to] do
      nil ->
        {:error, "unsupported currencies conversion"}
      val ->
        result = val * amount
        {:ok, result}
    end
  end

  defp rates do
    %{
      "EURGBP" => 0.851,
      "EURAUD" => 1.60097,
      "EURNZD" => 1.6786,
      "EURUSD" => 1.1839,
      "EURCAD" => 1.48286,
      "EURCHF" => 1.0739,
      "EURJPY" => 129.831,
      "GBPEUR" => 1.1738,
      "GBPAUD" => 1.888072,
      "GBPNZD" => 1.97225,
      "GBPUSD" => 1.39055,
      "GBPCAD" => 1.74178,
      "GBPCHF" => 1.26131,
      "GBPJPY" => 152.487,
      "AUDGBP" => 0.53143,
      "AUDEUR" => 0.62432,
      "AUDNZD" => 1.04855,
      "AUDUSD" => 0.73937,
      "AUDCAD" => 0.92607,
      "AUDCHF" => 0.67074,
      "AUDJPY" => 81.101,
      "NZDGBP" => 0.50687,
      "NZDAUD" => 0.9533,
      "NZDEUR" => 0.59542,
      "NZDUSD" => 0.7053,
      "NZDCAD" => 0.88325,
      "NZDCHF" => 0.63965,
      "NZDJPY" => 77.355,
      "USDGBP" => 0.71889,
      "USDAUD" => 1.35222,
      "USDNZD" => 1.4173,
      "USDEUR" => 0.8442,
      "USDCAD" => 1.25243,
      "USDCHF" => 0.90686,
      "USDJPY" => 109.67,
      "CADGBP" => 0.5735,
      "CADAUD" => 1.0794,
      "CADNZD" => 1.1311,
      "CADUSD" => 0.7982,
      "CADEUR" => 0.674,
      "CADCHF" => 0.7229,
      "CADJPY" => 87.572,
      "CHFGBP" => 0.7923,
      "CHFAUD" => 1.491,
      "CHFNZD" => 1.5623,
      "CHFUSD" => 1.1029,
      "CHFCAD" => 1.3803,
      "CHFEUR" => 0.9305,
      "CHFJPY" => 120.982,
      "JPYGBP" => 0.00655,
      "JPYAUD" => 0.01233,
      "JPYNZD" => 0.01293,
      "JPYUSD" => 0.00911950,
      "JPYCAD" => 0.01141600,
      "JPYCHF" => 0.00826400,
      "JPYEUR" => 0.00769860
    }
  end
end
