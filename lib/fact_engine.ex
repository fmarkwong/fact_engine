defmodule FactEngine do
  # returns map of inputs and query results e.g.
  # %{inputs: [are_friends: ["frog", "toad"], are_friends: ["alex", "sam"]], query_results: [[false, %{X: "alex"}]]}

  def process_file(path) do
    File.stream!(path)
    |> Enum.reduce(%{inputs: [], query_results: []}, fn line, acc ->
      case parse(line) do
        ["INPUT", statement, arguments] ->
          %{
            inputs: [process_input(statement, arguments) | acc.inputs],
            query_results: acc.query_results
          }

        ["QUERY", statement, arguments] ->
          %{
            inputs: acc.inputs,
            query_results: [process_query(statement, arguments, acc.inputs) | acc.query_results]
          }
      end
    end)
  end

  def parse(line) when is_binary(line) do
    with [_, action, statement, arguments] <-
           Regex.run(~r/(INPUT|QUERY) ([a-z_]+)+ \(([a-zA-Z1-9_(, )*]+)\)/, line) do
      arguments = String.split(arguments, ",", trim: true) |> Enum.map(&String.trim/1)
      statement = String.to_atom(statement)

      [action, statement, arguments]
    else
      _ -> raise "malformed input file"
    end
  end

  def process_input(statement, arguments) do
    {statement, arguments}
  end

  # returns false, a map of variables and their values upon matching or an empty map which means a match of a singular literal with no variables e.g. is_a_cat (lucy)
  def process_query(query_statement, query_arguments, inputs) do
    query_arguments_string = stringify(query_arguments)

    results =
      inputs
      |> Enum.filter(&match?({^query_statement, _x}, &1))
      |> Enum.map(fn input ->
        {_, input_arguments} = input
        input_arguments
      end)
      |> Enum.map(fn input_arguments ->
        input_arguments_string = stringify(input_arguments)

        code =
          pattern_matcher_generator(
            query_arguments_string,
            input_arguments_string,
            query_arguments
          )

        # TODO: Evaling is dangerous.  Tried to do this with macros,
        # but needed runtime eval, not compile time. Need to research
        # safter solution or workaround
        {result, _} = Code.eval_string(code)
        result
      end)

    !Enum.empty?(results) && results
  end

  # takes list of args and turns into string version
  # we couldn't use `inspect` because we need to 
  # conditionally apply quotes to the string element
  # depending on whether it is a variable or not
  def stringify(arguments) do
    arguments
    |> Enum.map(fn arg ->
      # if variable, omit surrounding quotes
      if is_variable?(arg) do
        String.downcase(arg)
      else
        "\"#{String.downcase(arg)}\""
      end
    end)
    |> Enum.join(", ")
    |> (&"[#{&1}]").()
  end

  # returns false, a map of variables and their values or an empty map which means a match of a singular literal with no variables  e.g. is_a_cat (lucy)
  def pattern_matcher_generator(query_arguments_string, input_arguments_string, query_arguments) do
    # filters for any variable entries in query arguments and compiles then into a map
    # e.g. %{X; x, Y; x} to be returned in below wtih statement upon pattern match 
    return_values_string =
      query_arguments
      |> Enum.uniq()
      |> Enum.filter(&is_variable?/1)
      |> Enum.map(fn arg ->
        "#{arg}: #{String.downcase(arg)}"
      end)
      |> Enum.join(", ")
      |> (&"%{#{&1}}").()

    # attempts pattern match query arguments with input arguments
    # upon match return variable and values
    """
      with #{query_arguments_string} <- #{input_arguments_string} do
        #{return_values_string}
      else
        _x -> false
      end
    """
  end

  def is_variable?(argument) do
    String.match?(argument, ~r/[A-Z]/)
  end

  # example results argument
  # %{input: [are_friends: ["frog", "toad"], are_friends: ["alex", "sam"]], query_results: [[false, %{X: "alex"}]]}
  #
  def print_results(results) do
    results.query_results
    |> Enum.reverse()
    |> Enum.map(&process_query_result/1)
  end

  def process_query_result(result) do
    case result do
      false ->
        IO.puts("---")
        IO.puts("false")

      input_match_results ->
        IO.puts("---")
        # if query produces no matches -> false 
        if Enum.all?(input_match_results, &(!&1)) do
          IO.puts("false")
        else
          # enumerate through list of query matches and print variables and associated values
          input_match_results
          |> Enum.filter(& &1)
          |> Enum.reverse()
          |> Enum.each(fn map ->
            # if query produces a match with no variables it means a match between singular literal, e.g. is_a_cat(lucy) so print true
            # else there was a match with variables,  print variables with values
            if map == %{} do
              IO.puts("true")
            else
              map
              |> Enum.reduce([], fn {k, v}, acc ->
                ["#{k}: #{v}" | acc]
              end)
              |> Enum.reverse()
              |> Enum.join(", ")
              |> IO.puts()
            end
          end)
        end
    end
  end
end

Enum.to_list(1..4)
|> Enum.each(fn i ->
  IO.puts("Running with example ##{i} data")
  IO.puts("===============================")

  FactEngine.process_file("test/examples/#{i}/in.txt")
  |> FactEngine.print_results()

  IO.puts("")
end)
