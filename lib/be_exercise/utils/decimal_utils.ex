defmodule Exercise.DecimalUtils do
   @moduledoc """
  Provides utility functions for creating and handling numbers from the Decimals library in a way that is consistent
  with the be-exercise Application and Database.
  """
  import Decimal

  @doc """
  Returns a new Decimal given a value, and sets the precision and rounding after the decimal point.
  ## Examples
    iex> DecimalUtils.new(1234567)
    Decimal.new("1234567.0000")
  """
  @spec new_decimal(float() | integer() | String.t()) :: Decimal.t()
  def new_decimal(value) when is_float(value), do: round(from_float(value), num_digits())
  def new_decimal(value) when is_integer(value) or is_binary(value), do: round(new(value), num_digits())

  @doc """
  Returns a consistent string representation of the decimal as configured by application.
  ## Examples
    iex> DecimalUtils.to_str(Decimal.new("1.234567"))
    "1.2345"
  """
  @spec to_str(Decimal.t()) :: String.t()
  def to_str(decimal) do
    to_string(round(decimal, num_digits()), :normal)
  end

  @doc """
  Returns the number of digits after the decimal point.
  ## Examples
    iex> DecimalUtils.num_digits()
    4
  """
  @spec num_digits() :: integer
  def num_digits() do
    Application.get_env(:be_exercise, :digits_after_decimal_point, 4)
  end
end
