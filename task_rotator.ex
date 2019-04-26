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
    IO.gets("#{question} ") |> String.trim
  end
end

defmodule TerminalTaskRotator do
  def index() do
    Terminal.clear
    Terminal.bold("Menu")
    IO.puts "[P] Projects"
    # IO.puts "[T] Tasks"
    IO.puts "[E] Exit"

    op = Terminal.ask_option

    status = case op do
      "P" -> Project.index
      "T" -> Task.index
      "E" -> :exit
      _ -> :ok
    end

    if status != :exit, do: index()
  end
end

defmodule Task do
  ### Tasks ###
  # [G] Get next task
  # [L] List tasks
  # [B] Back
  def index() do
    Terminal.clear
    Terminal.bold "Menu"

  end
end

defmodule Project do
  ### Projects ###
  # [$] ${project_name} ${project status}
  # [A] Add project
  # [B] Back
  def index(state_pid \\ nil) do
    state_pid = cond do
      state_pid == nil -> Project.build_state
      true -> state_pid
    end

    Terminal.clear
    Terminal.bold "Projects"
    Project.list state_pid
    IO.puts "[A] Add project"
    IO.puts "[B] Back"

    option = Terminal.ask_option
    option_int = Integer.parse option
    option_int = if option_int != :error, do: option_int |> elem(0), else: :error

    status = if option_int != :error && option_int < State.count state_pid do
      show state_pid, option_int
      true
    else
      case option do
        "A" -> :ok
        "B" -> :exit
        _ -> :ok
      end
    end

    if status == :exit do
      Project.clear_state state_pid
    else
      Project.index state_pid
    end
  end

  ### ${project_name} ###
  # [E] Edit
  # [D] Delete
  # [B] Back
  def show(state_pid, id) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold project.name
    IO.puts "[E] Edit"
    IO.puts "[D] Delete"
    IO.puts "[B] Back"

    option = Terminal.ask_option

    status = case option do
      "E" -> edit(state_pid, id)
      "D" -> delete(state_pid, id)
      "B" -> :exit
      _ -> :ok
    end

    if status == :ok, do: show(state_pid, id)
  end

  ### Delete ${project_name} ###
  def delete(state_pid, id) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold "Delete #{project.name}"
    option = Terminal.ask_input("Are you sure, you want to delete?([y/N])") |> String.trim

    case option do
      "y" -> State.delete(state_pid, id)
      _ -> :ok
    end
  end

  ### Edit ${project_name} ###
  # Name(${project_name}): ...
  def edit(state_pid, id) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold "Edit #{project.name}"
    new_name = Terminal.ask_input("Name(#{project.name}):") |> String.trim
    project = cond do
      new_name != "" -> %{ project | name: new_name }
      true -> project
    end

    State.update(state_pid, id, project)
  end

  def list(state_pid) do
    projects = State.all state_pid
    list_item 0, projects, State.count state_pid
  end

  def list_item(id, projects, size) do
    if id < size do
      project = projects |> Enum.at(id)
      IO.puts "[#{id}] #{project.name} #{ if project.complete, do: '-> Completed' }"
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
      [ Project_t.new("Projeto 1", false), Project_t.new("Projeto 2", true) ]
    else
      [ Project_t.new("Projeto 1", false), Project_t.new("Projeto 2", true) ]
    end
  end

  def clear_state(state_pid) do
    State.stop state_pid
  end
end

defmodule Project_t do
  defstruct name: nil, complete: nil

  def new(name, complete) do
    %Project_t{ name: name, complete: complete }
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

  def handle_call(:count, _, state) do
    { :reply, state |> Enum.count(), state }
  end

  def handle_call({ :get, id }, _, state) do
    { :reply, state |> Enum.at(id), state }
  end

  def handle_call({ :update, id, new }, _, state) do
    { :reply, state, List.replace_at(state, id, new) }
  end

  def handle_call({ :delete, id }, _, state) do
    new_state = List.pop_at(state, id) |> elem(1)
    { :reply, :deleted, new_state }
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

  def get(pid, id) do
    GenServer.call pid, { :get, id }
  end

  def update(pid, id, new) do
    GenServer.call pid, { :update, id, new }
  end

  def delete(pid, id) do
    GenServer.call pid, { :delete, id }
  end
end

TerminalTaskRotator.index

### ${project_name} ###
# [D] Mark as complete
# [B] Back

### Task list ###
# [$] ${project_name}
# [B] Back