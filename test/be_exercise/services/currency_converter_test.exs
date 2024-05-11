defmodule Exercise.Services.CurrencyConverterTest do
  @moduledoc false

  use ExUnit.Case
  alias Exercise.Services.CurrencyConverter, as: Converter

  describe "convert/3" do
    test "converting from a less valuable to a more valuable currency results in a smaller amount" do
      amount = 100

      {:ok, result} = Converter.convert("JPY", "GBP", amount)

      assert result < amount
    end

    test "when one of the currencies is unsupported we get an error tuple as a result" do
      amount = 100

      assert {:error, :unsupported_currency} =
               Converter.convert("XYZ", "GBP", amount)
      assert {:error, :unsupported_currency} =
        Converter.convert("GBP", "XYZ", amount)
    end

    test "converting 0 returns 0" do
      assert {:ok, 0.0} = Converter.convert("GBP", "JPY", 0)
      assert {:ok, 0.0} = Converter.convert("GBP", "JPY", 0.0)
    end

    test "return error on negative amount" do
      amount = -10.0
      assert {:error, :negative_amount_given} = Converter.convert("GBP", "JPY", amount)
    end
  end
end
