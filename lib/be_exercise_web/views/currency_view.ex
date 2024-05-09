defmodule ExerciseWeb.CurrencyView do
  use ExerciseWeb, :view
  alias ExerciseWeb.CurrencyView

  def render("index.json", %{currencies: currencies}) do
    %{data: render_many(currencies, CurrencyView, "currency.json")}
  end

  def render("show.json", %{currency: currency}) do
    %{data: render_one(currency, CurrencyView, "currency.json")}
  end

  def render("currency.json", %{currency: currency}) do
    %{id: currency.id, code: currency.code, name: currency.name, symbol: currency.symbol}
  end
end
