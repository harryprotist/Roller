defmodule Pool do

  def setup do
    pool_pid = spawn_link fn -> pool_loop([]) end
    Process.register(pool_pid, :pool)
  end

  defp get_entry(list, conn) do
    Enum.find_value(list, fn c ->
      case c do
        %{conn: ^conn} -> c
        _ -> false
      end
    end)
  end

  defp pool_loop(list) do
#    try do
      receive do
        {:add, conn, id, name, color, room} ->
          list = [ %{
            conn:   conn,
            id:     id,
            name:   name,
            color:  color,
            room:   room
          } | list ]
        {:get, conn, sender} ->
          room = get_entry(list, conn)[:room]
          result = Enum.filter(list, fn c ->
            c[:room] == room
          end)
          send sender, result
        {:del, conn} ->
          e = get_entry(list, conn)
          IO.inspect e
          IO.puts("* Before: " <> to_string(length(list)))
          list = Enum.filter(list, fn c ->
            c[:conn] != conn
          end) 
          IO.puts("*  After: " <> to_string(length(list)))
          Enum.map(list, fn c ->
            Socket.Web.send!(c[:conn], {:text, Poison.Encoder.encode(%{
              type: "del",
              id: e[:id]
            }, []) |> to_string}) 
          end)
        {:send, conn, msg} ->
          e = get_entry(list, conn)
          Enum.map(list, fn c ->
            if c[:room] == e[:room] do
              Socket.Web.send(c[:conn], {:text, msg})
            end
          end)  
        {:get_entry, conn, sender} ->
          send sender, (get_entry(list, conn))
      end 
#    rescue
#      e -> IO.inspect e 
#    end
     pool_loop(list)
  end

  def add(conn, id, name, color, room) do
    send :pool, {:add, conn, id, name, color, room}
  end
  def get(conn) do
    send :pool, {:get, conn, self()}
    receive do x -> x end
  end
  def del(conn) do
    send :pool, {:del, conn}
  end
  def msg(conn, msg) do
    send :pool, {:send, conn, msg}
  end
  def entry(conn) do
    send :pool, {:get_entry, conn, self()}
    receive do x -> x end
  end

end
