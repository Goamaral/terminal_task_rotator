defmodule Terminal do
  def bold(text) do
    IO.puts "#{IO.ANSI.bright}#{text}#{IO.ANSI.normal}"
  end

  def clear do
    IO.puts IO.ANSI.clear
  end

  def ask_option do
    IO.write "\nOption: "
    IO.gets("") |> String.trim
  end

  def ask_input(question) do
    IO.gets(question) |> String.trim
  end
end

defmodule TerminalTaskRotator do
  def menu() do
    Terminal.clear
    Terminal.bold("Menu")
    IO.puts "[P] Projects"
    IO.puts "[T] Tasks"
    IO.puts "[E] Exit"

    op = Terminal.ask_option

    case op do
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
    Terminal.bold "Projects"
    Project.list state_pid
    IO.puts "[A] Add project"
    IO.puts "[B] Back"

    option = Terminal.ask_option
    option_int = Integer.parse option
    option_int = if option_int != :error, do: option_int |> elem(0), else: :error

    if option_int != :error && option_int < State.count state_pid do
      IO.puts "IS A NUMBER #{option_int}" # HERE
    end

    case option do
      "A" -> :ok
      _ -> :ok
    end

    Project.clear_state state_pid
  end

  def list(state_pid) do
    projects = State.all state_pid
    list_item projects, projects |> tuple_size
  end

  def list_item(id \\ 0, projects, size) do
    if id < size do
      project = projects |> elem(id)
      IO.puts "[#{id}] #{project.name} #{ if project.done, do: '-> Done' }"
      list_item id + 1, projects, size
    end
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

  def clear_state(state_pid) do
    State.stop state_pid
  end
end

defmodule Project_t do
  defstruct name: nil, done: nil

  def new(name, done) do
    %Project_t{ name: name, done: done }
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
    { :reply, state, Tuple.append(state, item) }
  end

  def handle_call(:count, _, state) do
    { :reply, state |> tuple_size, state }
  end

  # API
  def all(pid) do
    GenServer.call pid, :all
  end

  def add(pid, item) do
    GenServer.call pid, { :add, item }
  end

  def count(pid) do
    GenServer.call pid, :count
  end

  def stop(pid) do
    GenServer.stop pid
  end
end

TerminalTaskRotator.menu

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