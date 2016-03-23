window.roller_client = null;
window.my_color = null;

function set_room(name) {
  var room = document.getElementById("room");
  room.innerHTML = name; 
}

function roller_join(name) {
  window.roller_client.send(JSON.stringify({
    "type": "join",
    "name": name
  })); 
}

function add_person(obj) {
  var people = document.getElementById("people");
  var div = document.createElement("DIV");
  div.setAttribute("class", "person");
  div.setAttribute("style", "background:"+obj.color+";");
  div.innerHTML = obj.name;

  people.appendChild(div);
}

function add_roll(obj) {
  var rolls = document.getElementById("rolls");
  var div = document.createElement("DIV");
  div.setAttribute("class", "roll"); 
  div.setAttribute("style", "background:"+obj.color+";");
  div.setAttribute("title", obj.text);
  div.innerHTML = obj.roll;

  rolls.appendChild(div);
}

function del_person(obj) {
  var people = document.getElementById("people");
  var children = Array.prototype.slice.call(people.childNodes);
  children.forEach(function(child) {
    if (child.innerHTML === obj.name) {
      people.removeChild(child);
    }
  });
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
      window.my_color = msg.color
      for (var i = 0; i < msg.people.length; i++) {
        add_person(msg.people[i]);
      }
    } else if (msg.type === "del") {
      del_person(msg)
    }
  };
}
window.onload = function() {
  var name = window.prompt("Enter your name", "Nobody")
  var room = window.prompt("Enter your room")
  set_room(room);
  roller_connect();
  window.roller_client.onopen = function() {
    roller_join(name);
  }
}

function roller_roll() {
  var num = document.getElementById("rnumber").value | 0;
  var sides = document.getElementById("rsides").value | 0;
  window.roller_client.send(JSON.stringify({
    "type": "roll",
    "num" : num,
    "roll": sides,
    "color": my_color
  }));
}
