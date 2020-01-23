### TODO ###
# Read projects from file
# Split in different files

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

defmodule Router do
  def go_to(route \\ :home, state_pid \\ nil) do
    state_pid = cond do
      state_pid == nil -> build_state()
      true -> state_pid
    end

    case route do
      :home -> TerminalTaskRotator.index(state_pid)
      :projects -> ProjectMenu.index(state_pid)
      :tasks -> TaskMenu.index(state_pid)
      :exit -> 
        export_state(state_pid)
        clear_state(state_pid)
    end
  end

  def build_state do
    ps = import_state()
    State.start_link(ps) |> elem(1)
  end

  def import_state do
    file_t = File.read "projects.json"
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

  def export_state(state_pid) do
    File.write("projects.json", Poison.encode!(State.all(state_pid)))
  end
end

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

    case op do
      "G" -> next(state_pid); Router.go_to(:tasks, state_pid)
      "L" -> list(state_pid); Router.go_to(:tasks, state_pid)
      "B" -> Router.go_to(:home, state_pid)
      _ -> index(state_pid)
    end
  end

  def next(state_pid) do
    { project, id } = State.next(state_pid)
    Terminal.clear
    Terminal.bold "Next task"

    unless project == nil do
      IO.puts "#{project.name} Due date: #{project.due_date} Priority: #{project.priority}"
      IO.puts "[C] Mark as completed"
      IO.puts "[B] Back"

      op = Terminal.ask_option

      case op do
        "C" -> completed(state_pid, id, project)
        _ -> :ok
      end
    else
      Terminal.error "No tasks available"
      IO.puts "[B] Back"

      Terminal.ask_option
    end
  end

  def list(state_pid) do
    Terminal.bold "Tasks"

    projects = State.all(state_pid)
      |> Enum.reject(fn project -> project.complete end)
      |> Enum.sort(&(Project.score(&1) > Project.score(&2)))

    size = Enum.count(projects)

    if size > 0 do
      list_item 0, projects, size
    else
      Terminal.error "No tasks available"
    end

    IO.puts "[B] Back"
    Terminal.ask_option
  end

  def list_item(id, projects, size) do
    if id < size do
      project = projects |> Enum.at(id)
      IO.puts "#{project.name} Due date: #{project.due_date} Priority: #{project.priority}"
      list_item id + 1, projects, size
    end
  end

  def completed(state_pid, id, project) do
    project = %{ project | complete: true }
    State.update state_pid, id, project
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

    option_s = Terminal.ask_option
    {option, option_valid} = Terminal.parse_int(option_s)

    if option_valid && option < State.count state_pid do
      show state_pid, option
    else
      case option_s do
        "A" -> add(state_pid); Router.go_to(:projects, state_pid)
        "B" -> :home; Router.go_to(:home, state_pid)
        _ -> index(state_pid)
      end
    end
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

    priority = Terminal.ask_input("Priority(0-10, Smaller is less urgent):") |> String.trim
    {priority, priority_valid} = Terminal.parse_int(priority)
    priority_valid = priority_valid && priority <= 10 && priority >= 0

    msgs = unless priority_valid do
      msgs ++ ["Priority not valid"]
    else
      msgs
    end

    due_date = Terminal.ask_input("Due date(yyyy-mm-dd):") |> String.trim |> String.split("-")
    due_date = Enum.map(due_date, fn part -> Terminal.parse_int(part) end)
    due_date_valid = Enum.map(due_date, fn part -> elem(part, 1) end)
    due_date_valid = Enum.reduce(due_date_valid, fn part, acc -> acc && part end)
    due_date = Enum.map(due_date, fn part -> elem(part, 0) end)
    due_date = List.to_tuple(due_date)
    due_date = %Date {
      year: elem(due_date, 0),
      month: elem(due_date, 1),
      day: elem(due_date, 2)
    }

    msgs = unless due_date_valid do
      msgs ++ ["Date not valid"]
    else
      msgs
    end

    project = cond do
      msgs == [] -> Project.new(name, due_date, priority)
      :ok -> nil
    end

    if project != nil do
      State.add state_pid, project
    else
      add state_pid, msgs
    end
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

    case option do
      "E" -> edit(state_pid, id); Router.go_to(:projects, state_pid)
      "D" -> delete(state_pid, id); Router.go_to(:projects, state_pid)
      "B" -> Router.go_to(:projects, state_pid)
      _ -> show(state_pid, id)
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
  def edit(state_pid, id, msgs \\ []) do
    project = State.get(state_pid, id)

    Terminal.clear
    Terminal.bold "Edit #{project.name}"

    if msgs != [], do: Terminal.error(Enum.join(msgs, "\n"))
    msgs = []

    name = Terminal.ask_input("Name(#{project.name}):") |> String.trim
    name = if name == "" do
      project.name
    else
      name
    end

    priority = Terminal.ask_input("Priority(#{project.priority}):") |> String.trim
    {priority, priority_valid} = if priority == "" do
      {project.priority, true}
    else
      {priority, priority_valid} = Terminal.parse_int(priority)
      {priority, priority_valid && priority <= 10 && priority >= 0}
    end

    msgs = unless priority_valid do
      msgs ++ ["Priority not valid"]
    else
      msgs
    end

    due_date = Terminal.ask_input("Due date(#{project.due_date}):") |> String.trim
    {due_date, due_date_valid} = if due_date == "" do
      {project.due_date, true}
    else
      due_date = due_date |> String.split("-")
      due_date = Enum.map(due_date, fn part -> Terminal.parse_int(part) end)
      due_date_valid = Enum.map(due_date, fn part -> elem(part, 1) end)
      due_date_valid = Enum.reduce(due_date_valid, fn part, acc -> acc && part end)
      due_date = Enum.map(due_date, fn part -> elem(part, 0) end)
      due_date = List.to_tuple(due_date)
      if tuple_size(due_date) == 3 do
        due_date = %Date {
          year: elem(due_date, 0),
          month: elem(due_date, 1),
          day: elem(due_date, 2)
        }
        {due_date, due_date_valid}
      else
        {due_date, false}
      end

    end

    msgs = unless due_date_valid do
      msgs ++ ["Date not valid"]
    else
      msgs
    end

    project = cond do
      msgs == [] -> %{ project | name: name, due_date: due_date, priority: priority }
      :ok -> nil
    end

    if project != nil do
      State.update state_pid, id, project
    else
      edit state_pid, id, msgs
    end
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
  @derive [Poison.Encoder]
  defstruct name: "", complete: false, due_date: Date.utc_today, priority: 0

  def new(name \\ "", due_date \\ Date.utc_today, priority \\ 0, complete \\ false) do
    %Project{ name: name, complete: complete, priority: priority, due_date: due_date }
  end

  def score(project) do
    days = Date.diff(project.due_date, Date.utc_today)
    priority = project.priority + 1

    if days < 0 do
      -1 * days * priority
    else 
      if days > 0 do
        priority / days
      else
        priority
      end
    end
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

  def handle_call(:next, _, state) do
    { next_project, id } = state
      |> Enum.with_index
      |> Enum.reduce({ nil, nil }, fn { project, index }, { acc_project, acc_id } ->
        if project.complete do
          { acc_project, acc_id }
        else
          if acc_project != nil do
            acc_score = Project.score(acc_project)
            project_score = Project.score(project)

            if project_score > acc_score do
              { project, index }
            else
              { acc_project, acc_id }
            end
          else
            { project, index }
          end
        end
      end)

    { :reply, { next_project, id }, state }
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

  def next(pid) do
    GenServer.call pid, :next
  end
end

defmodule App do
  use Application

  def start(_type, _args) do
    Router.go_to
    {:ok, self() }
  end
end