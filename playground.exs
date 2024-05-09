out =
  1..100
  |> Task.async_stream(
    fn i ->
      case rem(i, 3) do
        0 -> {:ok, 0}
        1 -> Process.sleep(100)
        _ -> {:ok, 1}
      end
    end,
    timeout: 10,
    on_timeout: :kill_task
  )
  |> Enum.map(& &1)

IO.inspect(out)
