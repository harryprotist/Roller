defmodule Request do

  def handle(request, conn) do
    case request do
      %{type: "join"} -> join(request, conn)
      %{type: "roll"} -> roll(request)
      _ -> %{}
    end
  end

  def join(r, conn) do
    ucolor = Roller.color_next(self())
    Roller.pool_send(Poison.Encoder.encode(%{
      type: "join",
      name: r[:name],
      color: ucolor
    }, []) |> to_string)
    Roller.pool_add(conn, r[:name], ucolor)
    users = Roller.pool_get(self())
    resp = %{
      type: "setup",
      color: ucolor,
      people: (Enum.map(users, fn u ->
        {_, name, color} = u
        %{name: name, color: color}
      end))}
    Socket.Web.send!(
      conn,
      {:text, (Poison.Encoder.encode(resp, []) |> to_string)})
  end

  def roll(r) do
    droll = Enum.sum(Enum.map(( 1 .. r[:num] ), fn a ->
      round(:random.uniform * r[:roll])
    end))
    dtext = to_string(r[:num]) <> "d" <> to_string(r[:roll])
    resp = %{type: "roll", roll: droll, color: r[:color], text: dtext}
    Roller.pool_send(Poison.Encoder.encode(resp, []) |> to_string)
  end

end
