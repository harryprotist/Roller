defmodule Roller do

  def setup do
    server = Socket.Web.listen! 8800 
    color_pid = spawn_link fn -> color_loop(0, 5) end
    Pool.setup()
    Process.register(color_pid, :color)
    accept_loop(server)
  end

  def color_loop(cur, len) do
    receive do
      {:next, sender} ->
        send sender, cur
    end
    color_loop(rem(cur + 1, len), len)
  end
  def color_next(sender) do
    send :color, {:next, sender}
    receive do x -> x end
  end

  def accept_loop(server) do
    client = Socket.Web.accept!(server)
    Socket.Web.accept!(client)
    IO.puts "Added client"
    spawn fn -> 
      :random.seed(:os.timestamp)
      handle(client)
    end
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
