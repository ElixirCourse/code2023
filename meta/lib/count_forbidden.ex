defmodule CountForbidden do
  def minus_points(file) do
    {:ok, str} = File.read(file)

    {:ok, ast} = Code.string_to_quoted(str)

    {_, acc} =
      ast
      |> Macro.prewalk(
        [],
        fn
          {:if, _, _} = ast_fragment, acc ->
            {ast_fragment, [:if | acc]}

          {:cond, _, _} = ast_fragment, acc ->
            {ast_fragment, [:cond | acc]}

          {:unless, _, _} = ast_fragment, acc ->
            {ast_fragment, [:unless | acc]}

          ast_fragment, acc ->
            {ast_fragment, acc}
        end
      )

    acc |> Enum.count() |> Kernel.*(2)
  end
end
