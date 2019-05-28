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
end

defmodule TerminalTaskRotator do
  def index(state_pid \\ nil) do
    state_pid = cond do
      state_pid == nil -> build_state()
      true -> state_pid
    end

    Terminal.clear
    Terminal.bold "Menu"
    IO.puts "[P] Projects"
    IO.puts "[T] Tasks"
    IO.puts "[E] Exit"

    op = Terminal.ask_option

    status = case op do
      "P" -> ProjectMenu.index state_pid
      "T" -> TaskMenu.index state_pid
      "E" -> :exit
      _ -> :ok
    end

    if status == :exit do
      clear_state state_pid
    else
      index state_pid
    end
  end

  def build_state do
    ps = import_state()
    State.start_link(ps) |> elem(1)
  end

  def import_state do
    file_t = File.read "projects.db"
    today = Date.utc_today()
    if file_t |> elem(0) == :ok do
      [ Project.new("Projeto 1", Date.add(today, 2)), Project.new("Projeto 2", Date.add(today, 2), 0, true) ]
    else
      [ Project.new("Projeto 1", Date.add(today, 2)), Project.new("Projeto 2", Date.add(today, 2), 0, true) ]
    end
  end

  def clear_state(state_pid) do
    State.stop state_pid
  end
end

defmodule TaskMenu do
  ### Tasks ###
  # [G] Get next task
  # [L] List tasks
  # [B] Back
  def index(state_pid) do
    Terminal.clear
    Terminal.bold "Tasks"
    IO.puts "[G] Get next task"
    IO.puts "[L] List tasks"
    IO.puts "[B] Back"

    op = Terminal.ask_option

    status = case op do
      "G" -> :ok
      "L" -> :ok
      "B" -> :exit
    end

    if status == :ok, do: index(state_pid)
  end
end

defmodule ProjectMenu do
  ### Projects ###
  # [$] ${project_name} ${project status}
  # [A] Add project
  # [B] Back
  def index(state_pid) do
    Terminal.clear
    Terminal.bold "Projects"
    ProjectMenu.list state_pid
    IO.puts "[A] Add project"
    IO.puts "[B] Back"

    option = Terminal.ask_option
    option_int = Integer.parse option
    option_int = if option_int != :error, do: option_int |> elem(0), else: :error

    status = if option_int != :error && option_int < State.count state_pid do
      show state_pid, option_int
    else
      case option do
        "A" -> add state_pid
        "B" -> :exit
        _ -> :ok
      end
    end

    if status == :ok, do: index(state_pid)
  end

  ### Add project ###
  # Name: ...
  def add(state_pid, msgs \\ []) do
    Terminal.clear
    Terminal.bold "Add project"
    if msgs != [], do: Terminal.error(Enum.join(msgs, "\n"))
    msgs = []

    name = Terminal.ask_input("Name:") |> String.trim
    name_valid = name != ""

    msgs = unless name_valid do
      msgs ++ ["Name can't be blank"]
    else
      msgs
    end

    priority_s = Terminal.ask_input("Priority(Smaller is more urgent):") |> String.trim
    priority_valid = priority_s != ""

    priority = if priority_valid do
      Integer.parse(priority_s) |> elem(0)
    else
      nil
    end

    msgs = unless priority_valid do
      msgs ++ ["Priority not valid"]
    else
      msgs
    end

    project = cond do
      msgs == [] ->  Project.new name, Date.utc_today, priority
      :ok -> nil
    end

    if project != nil do
      State.add state_pid, project
    else
      add(state_pid, msgs)
    end

    :ok
  end

  ### Project ###
  # Name: ${project_name}
  # Due date: ${project_due_date}
  # Priority: ${project_priority}
  # Complete: ${project_complete}
  #
  # [E] Edit
  # [D] Delete
  # [B] Back
  def show(state_pid, id) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold "Project"
    IO.puts "Name: #{project.name}"
    IO.puts "Due date: #{project.due_date}"
    IO.puts "Priority: #{project.priority}"
    IO.puts "Complete: #{project.complete}"
    IO.puts ""

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

    if status == :ok do
      show(state_pid, id)
    else
      status
    end
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
end

defmodule Project do
  defstruct name: "", complete: false, due_date: Date.utc_today, priority: 0

  def new(name \\ "", due_date \\ Date.utc_today, priority \\ 0, complete \\ false) do
    %Project{ name: name, complete: complete, priority: priority, due_date: due_date }
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