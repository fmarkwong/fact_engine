defmodule FactEngineTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest FactEngine

  test "example 1" do
    assert (data = FactEngine.process_file("test/examples/1/in.txt")) == %{
             inputs: [are_friends: ["sam", "sam"], is_a_cat: ["lucy"]],
             query_results: [[%{Y: "sam"}], [%{}]]
           }

    assert capture_io(fn -> FactEngine.print_results(data) end) ==
             """
             ---
             true
             ---
             Y: sam
             """
  end

  test "example 2" do
    assert (data = FactEngine.process_file("test/examples/2/in.txt")) == %{
             inputs: [are_friends: ["frog", "toad"], are_friends: ["alex", "sam"]],
             query_results: [[false, %{X: "alex"}]]
           }

    assert capture_io(fn -> FactEngine.print_results(data) end) ==
             """
             ---
             X: alex
             """
  end

  test "example 3" do
    assert (data = FactEngine.process_file("test/examples/3/in.txt")) == %{
             inputs: [
               is_a_cat: ["bowler_cat"],
               loves: ["garfield", "lasagna"],
               is_a_cat: ["garfield"],
               is_a_cat: ["lucy"]
             ],
             query_results: [
               [%{FavoriteFood: "lasagna"}],
               [%{X: "bowler_cat"}, %{X: "garfield"}, %{X: "lucy"}],
               false
             ]
           }

    assert capture_io(fn -> FactEngine.print_results(data) end) ==
             """
             ---
             false
             ---
             X: lucy
             X: garfield
             X: bowler_cat
             ---
             FavoriteFood: lasagna
             """
  end

  test "example 4" do
    assert (data = FactEngine.process_file("test/examples/4/in.txt")) == %{
             inputs: [make_a_triple: ["5", "12", "13"], make_a_triple: ["3", "4", "5"]],
             query_results: [[false, false], [false, %{X: "3", Y: "5"}]]
           }

    assert capture_io(fn -> FactEngine.print_results(data) end) ==
             """
             ---
             X: 3, Y: 5
             ---
             false
             """
  end
end
