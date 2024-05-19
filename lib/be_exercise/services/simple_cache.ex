defmodule Exercise.Services.SimpleCache do
  @doc """
  An ETS driven cache, owned by a GenServer process running a periodic expiry checks on the contents of the cache.
  """
  use GenServer
  require Logger

  @default_expire_check_freq_ms 60_000  #1min
  @default_ttl_ms               60_000  #1min

  # Starts the GenServer
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  # GenServer callbacks
  @impl GenServer
  def init(name) do
    # Create the ETS table when the GenServer starts
    :ets.new(name, [:named_table, :public, {:read_concurrency, true}, {:write_concurrency, true}])
    expire_time = Application.get_env(:be_exercise, :simplecache_expire_check_freq_ms, @default_expire_check_freq_ms)

    Logger.info("Started new simple cache instance #{name}")
    Process.send_after(self(), :expire, expire_time) # schedule check for expired keys
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

    Process.send_after(self(), :expire, expire_time) # schedule next check
    {:noreply, state}
  end

  ## ====================================================
  ## API

  # API for setting the cache with an optional expiration time
  def insert(cache_name, key, value, ttl \\ @default_ttl_ms) do
    exp_time = System.monotonic_time(:millisecond) + ttl
    :ets.insert(cache_name, {key, {value, exp_time}})
    :ok
  end

  # API for getting a value from the cache
  def get(cache_name, key) do
    case :ets.lookup(cache_name, key) do
      [{_, {value, _}}] ->
        {:ok, value}
      [] ->
        {:error, :not_found}
    end
  end

  # API to manually expire a key from the cache (deletes it)
  def expire(cache_name, key) do
    :ets.delete(cache_name, key)
    :ok
  end

end
