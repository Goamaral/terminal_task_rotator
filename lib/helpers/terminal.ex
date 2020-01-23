defmodule Terminal do
  def bold(text, print \\ true) do
    str = "#{IO.ANSI.bright}#{text}#{IO.ANSI.reset}"

    if print do
      IO.puts str
    else
      str
    end
  end

  def error(text, print \\ true) do
    str = "#{IO.ANSI.light_red}#{text}#{IO.ANSI.reset}"

    if print do
      IO.puts str
    else
      str
    end
  end

  def clear do
    IO.puts IO.ANSI.clear
  end

  def ask_option do
    IO.write "\nOption: "
    IO.gets("") |> String.trim
  end

  def ask_input(question) do
    IO.gets("#{question} ") |> String.trim
  end

  def parse_int(str) do
    case Integer.parse(str) do
      {int, _} -> {int, true}
      _ -> {0, false}
    end
  end
end