defmodule Terminal do
  def bold(text) do
    IO.puts "#{IO.ANSI.bright}#{text}#{IO.ANSI.normal}"
  end

  def clear do
    IO.puts IO.ANSI.clear
  end
end

defmodule TerminalTaskRotator do
  def menu() do
    Terminal.clear
    Terminal.bold("Menu")
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
  def menu do
    state_pid = Project.build_state

    Terminal.clear
    Terminal.bold("Projects")
    Project.list state_pid
    IO.puts "[A] Add project"
    IO.puts "[B] Back"

    Project.clear_state state_pid
  end

  def build_state do
    ps = Project.import
    State.start_link(ps) |> elem(1)
  end

  def import do
    file_t = File.read "projects.db"
    if file_t |> elem(0) == :ok do
      { Project_t.new("Projeto 1", false), Project_t.new("Projeto 2", true) }
    else
      { Project_t.new("Projeto 1", false), Project_t.new("Projeto 2", true) }
    end
  end

  def list(state_pid) do
    projects = State.all state_pid
    item projects, projects |> tuple_size
  end

  def item(id \\ 0, projects, size) do
    if id < size do
      project = projects |> elem(id)
      IO.puts "[#{id}] #{project.name} #{ if project.status, do: '-> Done' }"
      item id + 1, projects, size
    end
  end

  def clear_state(state_pid) do
    State.stop state_pid
  end
end

defmodule Project_t do
  defstruct name: nil, status: nil

  def new(name, status) do
    %Project_t{ name: name, status: status }
  end
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

  def handle_call({ :add, item }, _, state) do
    { :reply, state, state ++ [item] }
  end

  # API
  def all(pid) do
    GenServer.call pid, :all
  end

  def add(pid, item) do
    GenServer.call pid, { :add, item }
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