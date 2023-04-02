defmodule ECIO.Device do
  @moduledoc """
  This began as the code from StringIO, which implements the IO server interface.
  There is not behavior for the IO server, just a set of possible io_request and io_reply messages.

  The idea of our device is to react to such meassges by sending them to processes - listeners.

  We can use it as a group leader like this:

    Process.group_leader(self(), ECIO.Device |> Process.whereis())


  The standart output basically works with a port like this one (same external app):

    port = Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof])

  To the port we send such meassages. This can't be tested with the repl as you won't be able to open that port just like that.

    send(port, [5|:unicode.characters_to_binary('hey',:utf8)])

  That port usualy is something like this:
  =port:#Port<0.5>
  State: CONNECTED|SOFT_EOF
  Slot: 40
  Connected: <0.64.0>
  Links: <0.64.0>
  Port controls linked-in driver: tty_sl -c -e
  Input: 402
  Output: 10223
  Queue: 0
  """

  use GenServer

  #######
  # API #
  #######

  def start_link(args, opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, args, name: name)
  end

  #############
  # Callbacks #
  #############

  @impl true
  def init([_args]) do
    {:ok, %{encoding: :unicode, input: "", output: "", capture_prompt: false}}
  end

  @impl true
  def handle_info({:io_request, from, reply_as, req}, state) do
    # The io_request message is what functions like `IO.puts` send to the device that is passed to them.
    # It is a 4-element tuple:
    # 1. `from` is a pid to send io_reply to.
    # 2. `reply_as` is a ref to reply it -> for sync.
    # 3. `req` is the actual request, for example : `{:put_chars, :unicode, "hey\n"}`
    state = io_request(from, reply_as, req, state)

    {:noreply, state}
  end

  def handle_info(_message, state) do
    # Ignore unknown messages, so we don't crash on them!

    {:noreply, state}
  end

  @impl true
  def handle_cast({:store_input, input}, state) do
    # To be called to store input, that can be read with something like `IO.gets`

    {:noreply, %{state | input: state.input <> input}}
  end

  ###########
  # Private #
  ###########

  # io_request/4
  #
  # Basically calls io_request/2 depending on the request.
  # Also replies by sending a io_reply message.
  # Can update the state by changing the input ot output buffers.

  defp io_request(from, reply_as, req, state) do
    {reply, state} = io_request(req, state)

    io_reply(from, reply_as, reply)

    state
  end

  # io_request/2
  #
  # Depending on the requests executes the right action:
  # 1. :put_chars is for output and sends chars or MFA that will generate chars, that's the request for IO.puts, IO.write, etc
  # 2. :get_chars reads a number of chars from the input or reads as much as it can up to :eof
  # 3. :get_line reads chars until :eof or \n is reached.
  # 4. :get_until is for reading untl some condition is true (using MFA)
  # 5. :get_password is for reading something that shouldn't be printed
  # 6. :setopts and :getopts are for setting and reading IO options like the encoding.
  # 7. :get_geometry is about how many characters can be printed on one line of the output
  # 8. :requests for supporting multiple requests. This code doesn't do that.
  #
  # You can try them with something like:
  #   pid = Process.group_leader()
  #   send(pid, {:io_request, self(), make_ref(), {:requests, [{:put_chars, "One\n"}, {:put_chars, "Two\n"}]}})

  defp io_request({:put_chars, chars} = req, state) do
    put_chars(:latin1, chars, req, state)
  end

  defp io_request({:put_chars, mod, fun, args} = req, state) do
    put_chars(:latin1, apply(mod, fun, args), req, state)
  end

  defp io_request({:put_chars, encoding, chars} = req, state) do
    put_chars(encoding, chars, req, state)
  end

  defp io_request({:put_chars, encoding, mod, fun, args} = req, state) do
    put_chars(encoding, apply(mod, fun, args), req, state)
  end

  defp io_request({:get_chars, prompt, count}, state) when count >= 0 do
    io_request({:get_chars, :latin1, prompt, count}, state)
  end

  defp io_request({:get_chars, encoding, prompt, count}, state) when count >= 0 do
    get_chars(encoding, prompt, count, state)
  end

  defp io_request({:get_line, prompt}, state) do
    io_request({:get_line, :latin1, prompt}, state)
  end

  defp io_request({:get_line, encoding, prompt}, state) do
    put_chars(encoding, prompt, {:put_chars, encoding, prompt, :nolocal_print}, state)

    get_line(encoding, prompt, state)
  end

  defp io_request({:get_until, prompt, mod, fun, args}, state) do
    io_request({:get_until, :latin1, prompt, mod, fun, args}, state)
  end

  defp io_request({:get_until, encoding, prompt, mod, fun, args}, state) do
    get_until(encoding, prompt, mod, fun, args, state)
  end

  defp io_request({:get_password, encoding}, state) do
    get_line(encoding, "", state)
  end

  defp io_request({:setopts, [encoding: encoding]}, state) when encoding in [:latin1, :unicode] do
    {:ok, %{state | encoding: encoding}}
  end

  defp io_request({:setopts, _opts}, state) do
    {{:error, :enotsup}, state}
  end

  defp io_request(:getopts, state) do
    {[binary: true, encoding: state.encoding], state}
  end

  defp io_request({:get_geometry, :columns}, state) do
    {{:error, :enotsup}, state}
  end

  defp io_request({:get_geometry, :rows}, state) do
    {{:error, :enotsup}, state}
  end

  defp io_request({:requests, reqs}, state) do
    io_requests(reqs, {:ok, state})
  end

  defp io_request(_, state) do
    {{:error, :request}, state}
  end

  # put_chars/4
  #
  # Our implementation prints the chars to the stadart output, but also sends them to listeners that can print them to
  # different places.

  defp put_chars(encoding, chars, req, state) do
    case :unicode.characters_to_binary(chars, encoding, state.encoding) do
      string when is_binary(string) ->
        case req do
          {:put_chars, _, _} ->
            IO.write([IO.ANSI.yellow(), "From device : ", IO.ANSI.reset()])
            IO.write(string)

          _ ->
            :noop
        end

        Registry.dispatch(
          ECIO.PubSub,
          ECIO.SocketPrinter.topic(),
          fn sups ->
            Enum.each(sups, fn {pid, _} ->
              GenServer.cast(pid, {:send, string})
            end)
          end
        )

        {:ok, %{state | output: state.output <> string}}

      {_, _, _} ->
        {{:error, {:no_translation, encoding, state.encoding}}, state}
    end
  rescue
    ArgumentError -> {{:error, req}, state}
  end

  # get_chars/4
  #
  # Just calls get_chars/3 and handles results or errors.

  defp get_chars(encoding, prompt, count, %{input: input} = state) do
    case get_chars(input, encoding, count) do
      {:error, _} = error ->
        {error, state}

      {result, input} ->
        {result, state_after_read(state, input, prompt, 1)}
    end
  end

  # get_chars/3
  #
  # Reads from the internal input buffer (from the process' state) up to the number of chars or until it is empty
  # All that is read is removed from the input buffer.

  defp get_chars("", _encoding, _count) do
    {:eof, ""}
  end

  defp get_chars(input, :latin1, count) when byte_size(input) < count do
    {input, ""}
  end

  defp get_chars(input, :latin1, count) do
    <<chars::binary-size(count), rest::binary>> = input
    {chars, rest}
  end

  defp get_chars(input, :unicode, count) do
    with {:ok, count} <- split_at(input, count, 0) do
      <<chars::binary-size(count), rest::binary>> = input
      {chars, rest}
    end
  end

  # get_line/3
  #
  # Basically reads from the state's input until `\n` or :eof is reached.
  # All that is read is removed from the input buffer.

  defp get_line(encoding, prompt, %{input: input} = state) do
    case bytes_until_eol(input, encoding, 0) do
      {:split, 0} ->
        {:eof, state_after_read(state, "", prompt, 1)}

      {:split, count} ->
        {result, remainder} = :erlang.split_binary(input, count)
        {result, state_after_read(state, remainder, prompt, 1)}

      {:replace_split, count} ->
        {result, remainder} = :erlang.split_binary(input, count)
        result = binary_part(result, 0, byte_size(result) - 2) <> "\n"
        {result, state_after_read(state, remainder, prompt, 1)}

      :error ->
        {{:error, :collect_line}, state}
    end
  end

  # get_until/6
  #
  # Mainly calls get_until/7 and handles errors or the result.
  # All that is read is removed from the input buffer.

  defp get_until(encoding, prompt, mod, fun, args, %{input: input} = state) do
    case get_until(input, encoding, mod, fun, args, [], 0) do
      {result, input, count} ->
        # Convert :eof to "" as they are both treated the same
        input =
          case input do
            :eof -> ""
            _ -> list_to_binary(input, encoding)
          end

        {get_until_result(result, encoding), state_after_read(state, input, prompt, count)}

      :error ->
        {:error, state}
    end
  end

  # get_until/7
  #
  # Uses the passed MFA to read until :eof is reached or the function returns `{:done, result, rest}`
  # The function can also return `{:more, acc}`, so it will be called again with that
  # The function receives the current acc, the input (can be :eof) and the passed args.
  # All that is read is removed from the input buffer, making it to be equal to `rest`.

  defp get_until("", encoding, mod, fun, args, continuation, count) do
    case apply(mod, fun, [continuation, :eof | args]) do
      {:done, result, rest} ->
        {result, rest, count + 1}

      {:more, next_continuation} ->
        get_until("", encoding, mod, fun, args, next_continuation, count + 1)
    end
  end

  defp get_until(chars, encoding, mod, fun, args, continuation, count) do
    case bytes_until_eol(chars, encoding, 0) do
      {kind, size} when kind in [:split, :replace_split] ->
        <<line::binary-size(size), rest::binary>> = chars

        case apply(mod, fun, [continuation, binary_to_list(line, encoding) | args]) do
          {:done, result, :eof} ->
            {result, rest, count + 1}

          {:done, result, extra} ->
            {result, extra ++ binary_to_list(rest, encoding), count + 1}

          {:more, next_continuation} ->
            get_until(rest, encoding, mod, fun, args, next_continuation, count + 1)
        end

      :error ->
        :error
    end
  end

  # io_requests/2

  defp io_requests([req | rest], {:ok, state}) do
    io_requests(rest, io_request(req, state))
  end

  defp io_requests(_, result) do
    result
  end

  # state_after_read/4
  #
  # For updating the state of the output buffer after read. This is to be dropped as it was just copied for the initial
  # code version.

  defp state_after_read(%{capture_prompt: false} = state, remainder, _prompt, _count) do
    %{state | input: remainder}
  end

  defp state_after_read(%{capture_prompt: true, output: output} = state, remainder, prompt, count) do
    output = <<output::binary, :binary.copy(IO.chardata_to_string(prompt), count)::binary>>
    %{state | input: remainder, output: output}
  end

  # split_at/3
  #
  # Helper for splitting strings. Maybe will be removed and we'll always work with iodata or chardata

  defp split_at(_, 0, acc),
    do: {:ok, acc}

  defp split_at(<<h::utf8, t::binary>>, count, acc),
    do: split_at(t, count - 1, acc + byte_size(<<h::utf8>>))

  defp split_at(<<_, _::binary>>, _count, _acc),
    do: {:error, :invalid_unicode}

  defp split_at(<<>>, _count, acc),
    do: {:ok, acc}

  # bytes_until_eol/3
  #
  # Returns bytes until the end of the current line.

  defp bytes_until_eol("", _, count), do: {:split, count}
  defp bytes_until_eol(<<"\r\n"::binary, _::binary>>, _, count), do: {:replace_split, count + 2}
  defp bytes_until_eol(<<"\n"::binary, _::binary>>, _, count), do: {:split, count + 1}

  defp bytes_until_eol(<<head::utf8, tail::binary>>, :unicode, count) do
    bytes_until_eol(tail, :unicode, count + byte_size(<<head::utf8>>))
  end

  defp bytes_until_eol(<<_, tail::binary>>, :latin1, count) do
    bytes_until_eol(tail, :latin1, count + 1)
  end

  defp bytes_until_eol(<<_::binary>>, _, _), do: :error

  # binary_to_list/2

  defp binary_to_list(data, :unicode) when is_binary(data), do: String.to_charlist(data)
  defp binary_to_list(data, :latin1) when is_binary(data), do: :erlang.binary_to_list(data)

  # list_to_binary/2

  defp list_to_binary(data, _) when is_binary(data), do: data
  defp list_to_binary(data, :unicode) when is_list(data), do: List.to_string(data)
  defp list_to_binary(data, :latin1) when is_list(data), do: :erlang.list_to_binary(data)

  # get_until_result/2

  defp get_until_result(data, encoding) when is_list(data), do: list_to_binary(data, encoding)
  defp get_until_result(data, _), do: data

  # io_reply/3
  #
  # Sends the io_reply message back to the io_request process.
  # It is in the form `{:io_reply, reply_as, reply}` and is sent to the `from` pid of the `:io_request`.
  # The reply_as ref is the same as what was sent with the `:io_request`. The reply is in the form of `:ok` or `{:error, error}`

  defp io_reply(from, reply_as, reply) do
    send(from, {:io_reply, reply_as, reply})
  end
end
