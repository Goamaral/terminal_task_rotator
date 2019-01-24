defmodule Font do
  def bold(text) do
    "#{IO.ANSI.bright}#{text}#{IO.ANSI.normal}"
  end
end

defmodule TerminalTaskRotator do
  def menu() do
    IO.ANSI.clear
    IO.puts Font.bold("Menu")
    IO.puts "[P] Projects"
    IO.puts "[T] Tasks"
    IO.puts "[E] Exit"

    IO.write "\nOption: "

    case IO.read(1) do
      "P" -> Project.menu
      #'T' -> Task.menu
      _ -> :ok
    end
  end
end

defmodule Project do
### Projects ###
# [$] ${project_name} ${project status}
# [A] Add project
# [B] Back
  def menu(state_pid \\ Project.start_state) do
    IO.puts Font.bold("Projects")


    State.stop state_pid
  end

  def start_state do
    State.start_link(Project.import) |> elem(1)
  end

  def import do
    file_t = File.read "projects.db"
    if file_t |> elem(0) == :ok do
      ["FILLED"]
    else
      []
    end
  end
end

defmodule Project_t do
  defstruct name: ""
end

defmodule State do
  use GenServer

  # GenServer
  def start_link(state \\ []) do
    GenServer.start_link __MODULE__, state
  end

  def init(state) do
    { :ok, state }
  end

  def handle_call(:all, _, state) do
    { :reply, state, state }
  end

  def handle_call({ :push, item }, _, state) do
    { :reply, state, state ++ [item] }
  end

  # API
  def all(pid) do
    GenServer.call pid, :all
  end

  def push(pid, item) do
    GenServer.call pid, { :push, item }
  end

  def stop(pid) do
    GenServer.stop pid
  end
end

TerminalTaskRotator.menu


### Add project ###
# Name: ...

### ${project_name} ###
# [E] Edit
# [D] Delete
# [B] Back

### Edit ${project_name} ###
# Name(${project_name}): ...

### Tasks ###
# [G] Get next task
# [L] List ordered tasks
# [B] Back

### ${project_name} ###
# [D] Done
# [B] Back

### Task list ###
# [$] ${project_name}
# [B] Back