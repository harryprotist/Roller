window.roller_client = null;
window.my_color = null;
window.my_room = null;
window.my_name = null;

window.roller_colors = [
  "#F85831",
  "#A3A948",
  "#CE1836",
  "#009989",
  "#EDB92E"
];

function set_room() {
  var room = document.getElementById("room");
  room.innerHTML = window.my_room; 
}

function roller_join() {
  window.roller_client.send(JSON.stringify({
    "type": "join",
    "name": window.my_name,
    "room": window.my_room
  })); 
}

function clear_rolls() {
  var rolls = document.getElementById("rolls");
  rolls.innerHTML = "";
}

function add_person(obj) {
  var people = document.getElementById("people");
  var div = document.createElement("DIV");
  var color = window.roller_colors[obj.color];
  div.setAttribute("class", "person");
  div.setAttribute("style", "background:"+color+";");
  div.setAttribute("id", obj.id);
  div.innerHTML = obj.name;

  people.appendChild(div);
}

function add_roll(obj) {
  var rolls = document.getElementById("rolls");
  var div = document.createElement("DIV");
  var color = window.roller_colors[obj.color];
  div.setAttribute("class", "roll"); 
  div.setAttribute("style", "background:"+color+";");
  div.setAttribute("title", obj.text);
  div.innerHTML = obj.roll;

  rolls.appendChild(div);
}

function del_person(obj) {
  var person = document.getElementById(obj.id);
  person.parentElement.removeChild(person);
}

function roller_connect() {
  window.roller_client = new WebSocket("ws://localhost:8800");
  window.roller_client.onmessage = function(event) {
    
    var msg = JSON.parse(event.data);
    console.log(msg);

    if (msg.type === "roll") {
      add_roll(msg);     
    } else if (msg.type === "join") {
      add_person(msg);
    } else if (msg.type === "setup") {
      window.my_color = msg.color;
      for (var i = 0; i < msg.people.length; i++) {
        add_person(msg.people[i]);
      }
    } else if (msg.type === "del") {
      del_person(msg)
    }
  };
}
window.onload = function() {
  window.my_name = window.prompt("Enter your name", "Nobody")
  window.my_room = window.prompt("Enter your room")
  set_room();
  roller_connect();
  window.roller_client.onopen = function() {
    roller_join(name);
  }
}

function roller_roll() {
  var num = document.getElementById("rnumber").value | 0;
  var sides = document.getElementById("rsides").value | 0;
  var bonus = document.getElementById("rbonus").value | 0;
  window.roller_client.send(JSON.stringify({
    "type": "roll",
    "num" : num,
    "roll": sides,
    "bonus" : bonus,
    "color": window.my_color,
    "room" : window.my_room 
  }));
}
