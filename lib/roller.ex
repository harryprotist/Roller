defmodule Roller do

  def setup do
    :random.seed(:os.timestamp)
    server = Socket.Web.listen! 8800 
    color_pid = spawn_link fn -> color_loop([
      "#a3a948",
      "#edb92e",
      "#f85931",
      "#ce1836",
      "#009989"
    ]) end
    Pool.setup()
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
        Pool.del(conn)
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
