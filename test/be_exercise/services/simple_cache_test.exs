defmodule Exercise.Services.SimpleCacheTest do
  @moduledoc false

  use ExUnit.Case
  alias Exercise.Services.SimpleCache

  describe "testing cache functionality" do
    @cache_name :employee_metrics

    test "test employee_metrics cache insert and get" do
      key = "country"
      value = "some work done for country"

      SimpleCache.insert(@cache_name, key, value, 1000)

      assert {:ok, value} == SimpleCache.get(@cache_name, key)
    end

    test "test employee_metrics cache automatic expiration" do
      key = "country1"
      value = "some work done for country"

      SimpleCache.insert(@cache_name, key, value, 1)
      Process.sleep(5)
      Process.send(@cache_name, :expire, [])    # cache processes are named
      Process.sleep(5)
      assert {:error, :not_found} = SimpleCache.get(@cache_name, key)

    end


  end
end
