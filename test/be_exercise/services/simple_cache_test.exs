defmodule Exercise.Services.SimpleCacheTest do
  @moduledoc false

  use ExUnit.Case
  alias Exercise.Services.{SimpleCache, SimpleCacheSup}

  describe "testing employee metrics cache functionality" do
    test "test employee_metrics cache insert and get" do
      key = "country"
      value = "some work done for country"

      SimpleCache.insert(cache_name(), key, value, 1000)

      assert {:ok, value} == SimpleCache.get(cache_name(), key)
    end

    test "test employee_metrics cache automatic expiration" do
      key = "country1"
      value = "some work done for country"

      SimpleCache.insert(cache_name(), key, value, 1)
      Process.sleep(5)
      # cache processes are named
      Process.send(cache_name(), :expire, [])
      Process.sleep(5)
      assert {:error, :not_found} = SimpleCache.get(cache_name(), key)
    end

    test "test employee_metrics cache manual expiration" do
      key = "country1"
      value = "some work done for country"

      SimpleCache.insert(cache_name(), key, value, 1000)
      SimpleCache.expire(cache_name(), key)
      assert {:error, :not_found} = SimpleCache.get(cache_name(), key)
    end

    # returns the cache name
    defp cache_name() do
      SimpleCacheSup.employee_metrics_cache()
    end
  end
end
