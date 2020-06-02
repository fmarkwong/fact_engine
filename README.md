# FactEngine

by Mark Wong

This project is in Elixir.  Make sure you have it installed per https://elixir-lang.org/install.html.

To run, in project root directory (`cd fact_engine`):
`elixir lib/fact_engine.ex`

To run tests:
`mix test`

This reads the example input files line by line and parses them out to action | statement | arguments. For example: `INPUT is_a_cat (lucy)`

INPUTs are accumulated in a map.  Those are used by `FactEngine#process_query` where query_arguments_string and input_arguments_string are used to dynamically pattern match.  The results are stored in a map like this.

%{
  inputs: [are_friends: ["sam", "sam"], is_a_cat: ["lucy"]],
  query_results: [[%{Y: "sam"}], [%{}]]
}

`FactEngine#print_query_result` takes the above `query_results` and prints out dashes and the query reults (true, false, a map, etc) e.g.

---
true
---
Y: sam
