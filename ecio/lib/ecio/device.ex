defmodule ECIO.Device do
  @moduledoc false

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
    state = io_request(from, reply_as, req, state)

    {:noreply, state}
  end

  def handle_info(_message, state) do
    # Ignore unknown messages!

    {:noreply, state}
  end

  ###########
  # Private #
  ###########

  # io_request/4

  defp io_request(from, reply_as, req, state) do
    {reply, state} = io_request(req, state)

    io_reply(from, reply_as, reply)

    state
  end

  # io_request/2

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
    IO.write([IO.ANSI.blue(), "From device : ", IO.ANSI.reset()])
    input = IO.gets(prompt)
    state = %{state | input: input}

    io_request({:get_line, :latin1, prompt}, state)
  end

  defp io_request({:get_line, encoding, prompt}, state) do
    IO.write([IO.ANSI.red(), "From device : ", IO.ANSI.reset()])
    input = IO.gets(prompt)
    state = %{state | input: input}

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

  defp put_chars(encoding, chars, req, state) do
    case :unicode.characters_to_binary(chars, encoding, state.encoding) do
      string when is_binary(string) ->
        IO.write([IO.ANSI.yellow(), "From device : ", IO.ANSI.reset()])
        IO.write(string)

        {:ok, %{state | output: state.output <> string}}

      {_, _, _} ->
        {{:error, {:no_translation, encoding, state.encoding}}, state}
    end
  rescue
    ArgumentError -> {{:error, req}, state}
  end

  # get_chars/4

  defp get_chars(encoding, prompt, count, %{input: input} = state) do
    case get_chars(input, encoding, count) do
      {:error, _} = error ->
        {error, state}

      {result, input} ->

        {result, state_after_read(state, input, prompt, 1)}
    end
  end

  # get_chars/3

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

  defp state_after_read(%{capture_prompt: false} = state, remainder, _prompt, _count) do
    %{state | input: remainder}
  end

  defp state_after_read(%{capture_prompt: true, output: output} = state, remainder, prompt, count) do
    output = <<output::binary, :binary.copy(IO.chardata_to_string(prompt), count)::binary>>
    %{state | input: remainder, output: output}
  end

  # split_at/3

  defp split_at(_, 0, acc),
    do: {:ok, acc}

  defp split_at(<<h::utf8, t::binary>>, count, acc),
    do: split_at(t, count - 1, acc + byte_size(<<h::utf8>>))

  defp split_at(<<_, _::binary>>, _count, _acc),
    do: {:error, :invalid_unicode}

  defp split_at(<<>>, _count, acc),
    do: {:ok, acc}

  # bytes_until_eol/3

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

  defp io_reply(from, reply_as, reply) do
    send(from, {:io_reply, reply_as, reply})
  end
end
