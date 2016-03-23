defmodule Roller do

  def setup do
    :random.seed(:os.timestamp)
    server = Socket.Web.listen! 8800 
    pool_pid = spawn fn -> pool_loop([]) end
    color_pid = spawn fn -> color_loop([
      "#a3a948",
      "#edb92e",
      "#f85931",
      "#ce1836",
      "#009989"
    ]) end
    Process.register(pool_pid, :pool)
    Process.register(color_pid, :color)
    accept_loop(server)
  end

  def color_loop(list) do
    receive do
      {:next, sender} ->
        [ first | rest ] = list
        list = Enum.concat(rest, [first])
        send sender, first
    end
    color_loop(list)
  end
  def color_next(sender) do
    send :color, {:next, sender}
    receive do x -> x end
  end

  def pool_loop(list) do
    try do
      receive do
        {:add, client, name, color} -> list = [ {client, name, color} | list ]
        {:get, sender} -> send sender, list
        {:del, conn} ->
          cname = Enum.find_value(list, fn c ->
            case c do
              {^conn, name, _} -> name
              _ -> false
            end
          end)
          IO.inspect cname
          list = Enum.drop_while(list, fn c ->
            case c do
              {^conn, _, _} -> true
              _ -> false
            end
          end)
          IO.inspect list
          Enum.map(list, fn c -> 
            IO.inspect c
            {uc, _, _} = c 
            Socket.Web.send!(uc, {:text, Poison.Encoder.encode(%{
              type: "del",
              name: cname 
            }, []) |> to_string}) 
          end)
        {:send, msg} ->
          IO.inspect msg
          Enum.map(list, fn c -> 
            {conn, _, _} = c
            Socket.Web.send!(conn, {:text, msg}) 
          end)
      end
      pool_loop(list)
    rescue
      e -> IO.inspect e
      pool_loop(list)
    end
  end
  def pool_add(client, name, color) do
    send :pool, {:add, client, name, color}
  end
  def pool_get(sender) do
    send :pool, {:get, sender}
    receive do x -> x end
  end
  def pool_del(conn) do
    send :pool, {:del, conn}
  end
  def pool_send(msg) do
    send :pool, {:send, msg} 
  end

  def accept_loop(server) do
    client = Socket.Web.accept!(server)
    Socket.Web.accept!(client)
    IO.puts "Added client"
    spawn fn -> handle(client) end
    accept_loop(server)
  end

  def handle(conn) do
    stop = false
    case Socket.Web.recv!(conn) do
      {:text, msg} -> respond(conn, msg)
      {:close, _, _} ->
        pool_del(conn)
        stop = true
      {:ping, _msg} -> Socket.Web.send!(conn, {:pong, ""})
    end
    unless stop do handle(conn) end
  end
  
  def respond(conn, msg) do
    msg_obj = Poison.Parser.parse!(msg, keys: :atoms!) 
    Request.handle(msg_obj, conn)
  end

end
