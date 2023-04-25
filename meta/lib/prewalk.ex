code = """
defmodule T do
 def foo(), do: 1
 def bar(), do: 2
 def baz(), do: 2 + 3 + 5
end
"""

{:ok, ast} = Code.string_to_quoted(code)
# Обхожда първо листата, после корена
Macro.postwalk(ast, [], fn node, acc -> 
  IO.puts(Macro.to_string(node))
  {node, acc}
end)
# Обхожда първо корена, после листата
Macro.prewalk(ast, [], fn node, acc ->
  IO.puts(Macro.to_string(node));
  {node, acc} 
end)
