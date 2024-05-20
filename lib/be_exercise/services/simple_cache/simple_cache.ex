defmodule Exercise.Services.SimpleCache do
  @doc """
  An ETS driven cache, owned by a GenServer process running a periodic expiry checks on the contents of the cache.
  """
  use GenServer
  require Logger

  # 1min
  @default_expire_check_freq_ms 60_000
  # 1min
  @default_ttl_ms 60_000

  # Starts the GenServer
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  # GenServer callbacks
  @impl GenServer
  def init(name) do
    # Create the ETS table when the GenServer starts
    :ets.new(name, [:named_table, :public, {:read_concurrency, true}, {:write_concurrency, true}])

    expire_time =
      Application.get_env(
        :be_exercise,
        :simplecache_expire_check_freq_ms,
        @default_expire_check_freq_ms
      )

    Logger.info("Started new simple cache instance #{name}")
    # schedule check for expired keys
    Process.send_after(self(), :expire, expire_time)
    {:ok, %{cache_name: name, expire_time: expire_time}}
  end

  @impl GenServer
  def handle_info(:expire, state = %{cache_name: name, expire_time: expire_time}) do
    Logger.debug("Running scheduled cache expiry #{name}")
    # scan and remove expired keys
    :ets.tab2list(name)
    |> Enum.each(fn {key, {_value, exp_time}} ->
      if System.monotonic_time(:millisecond) > exp_time do
        :ets.delete(name, key)
      end
    end)

    # schedule next check
    Process.send_after(self(), :expire, expire_time)
    {:noreply, state}
  end

  ## ====================================================
  ## API

  @doc """
  API for inserting into the cache with an optional expiration time.

  ## Examples
    iex> SimpleCache.insert(:my_cache, "key", "value")
    :ok
  """
  @spec insert(atom(), any(), any(), integer()) :: :ok
  def insert(cache_name, key, value, ttl \\ @default_ttl_ms) do
    exp_time = System.monotonic_time(:millisecond) + ttl
    :ets.insert(cache_name, {key, {value, exp_time}})
    :ok
  end

  @doc """
  API for retrieving a value from the cache.

  ## Examples
    iex> SimpleCache.get(:my_cache, "key")
    {:ok, "value"}

    iex> SimpleCache.get(:my_cache, "fake key")
    {:error, :not_found}
  """
  @spec get(atom(), any()) :: {:ok, any()} | {:error, :not_found}
  def get(cache_name, key) do
    case :ets.lookup(cache_name, key) do
      [{_, {value, _}}] ->
        {:ok, value}

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  API to manually expire a key from the cache (deletes it).

  ## Examples
    iex> SimpleCache.expire(:my_cache, "key")
    :ok
  """
  @spec get(atom(), any()) :: :ok
  def expire(cache_name, key) do
    :ets.delete(cache_name, key)
    :ok
  end
end
