defmodule FMI do
  import Kernel, except: [if: 2]

  defmacro if(condition, kw) do
    do_clause = Keyword.fetch!(kw, :do)
    else_clause = Keyword.get(kw, :else, nil)

    quote do
      IO.puts "Our if"
      case unquote(condition) do
        x when x in [false, nil] -> unquote(else_clause)
        _ -> unquote(do_clause)
      end
    end
  end

  defmacro unless(condition, kw) do
    do_clause = Keyword.fetch!(kw, :do)
    else_clause = Keyword.get(kw, :else, nil)

    quote do
      if(unquote(condition), do: unquote(else_clause), else: unquote(do_clause))
    end
  end
end
