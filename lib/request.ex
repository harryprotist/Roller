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
    }, []) |> to_string, r[:room])
    Roller.pool_add(conn, r[:name], ucolor, r[:room])
    users = Roller.pool_get(self(), r[:room])
    resp = %{
      type: "setup",
      color: ucolor,
      people: (Enum.map(users, fn u ->
        {_, name, color, _} = u
        %{name: name, color: color}
      end))}
    Socket.Web.send!(
      conn,
      {:text, (Poison.Encoder.encode(resp, []) |> to_string)})
  end

  def roll(r) do
    IO.inspect(r)
    droll = Enum.sum(Enum.map(( 1 .. r[:num] ), fn a ->
      trunc(:random.uniform * r[:roll] + 1.0)
    end)) + r[:bonus]
    dtext = to_string(r[:num]) <> "d" <>
            to_string(r[:roll]) <> "+" <>
            to_string(r[:bonus])
    resp = %{type: "roll", roll: droll, color: r[:color], text: dtext}
    Roller.pool_send(Poison.Encoder.encode(resp, []) |> to_string, r[:room])
  end

end
