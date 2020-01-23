defmodule TerminalTaskRotator do
  def index(state_pid) do
    Terminal.clear
    Terminal.bold "Menu"
    IO.puts "[P] Projects"
    IO.puts "[T] Tasks"
    IO.puts "[E] Exit"

    op = Terminal.ask_option

    case op do
      "P" -> Router.go_to(:projects, state_pid)
      "T" -> Router.go_to(:tasks, state_pid)
      "E" -> Router.go_to(:exit, state_pid)
      _ -> index(state_pid)
    end
  end
end
