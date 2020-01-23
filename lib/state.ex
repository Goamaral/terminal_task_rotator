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