defmodule Request do

  def handle(request, conn) do
    case request do
      %{type: "join"} -> join(request, conn)
      %{type: "roll"} -> roll(request, conn)
      _ -> %{}
    end
  end

  def join(r, conn) do
    ucolor = Roller.color_next(self())
    Pool.msg(conn, Poison.Encoder.encode(%{
      type: "join",
      name: r[:name],
      color: ucolor
    }, []) |> to_string)
    Pool.add(conn, r[:name], ucolor, r[:room])
    users = Pool.get(conn)
    resp = %{
      type: "setup",
      color: ucolor,
      people: (Enum.map(users, fn u ->
        %{name: u[:name], color: u[:color]}
      end))}
    Socket.Web.send!(
      conn,
      {:text, (Poison.Encoder.encode(resp, []) |> to_string)})
  end

  def roll(r, conn) do
    IO.inspect(r)
    droll = Enum.sum(Enum.map(( 1 .. r[:num] ), fn a ->
      trunc(:random.uniform * r[:roll] + 1.0)
    end)) + r[:bonus]
    e = Pool.entry(conn)
    dtext = to_string(r[:num]) <> "d" <>
            to_string(r[:roll]) <> "+" <>
            to_string(r[:bonus]) <> " " <>
            r[:name]
    resp = %{
      type: "roll",
      roll: droll,
      color: r[:color],
      text: dtext,
      name: e[:name]
    }
    Pool.msg(conn, Poison.Encoder.encode(resp, []) |> to_string)
  end

end
