import socket from "./socket"

let match = window.location.pathname.match(/^\/room\/([0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12})$/i)
let channel = null
if(match){
  // Now that you are connected, you can join channels with a topic:
  channel = socket.channel(`room:${match[1]}`, {})
  channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp); loadGameState(resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })


  let canvas = document.querySelector("canvas")
  let context = canvas.getContext("2d");

  let isPainting = false
  let lastPosition = [0,0]

  let game = null
  let clientPlayer = null

  function loadGameState(payload){
    game = payload[0]
    clientPlayer = payload[1]

    game.curves.forEach(curve => {
      curve.points.forEach((point, idx) => {
        if(idx == 0){
          context.beginPath()
          context.moveTo(point[0], point[1]);
        }
        else if(idx == curve.points.length - 1){
          context.stroke()
        }
        else {
          context.lineTo(point[0], point[1]);
          context.strokeStyle = curve.author.color
        }
      })
    })
  }

  function paintCanvas(lastPosition, currentPosition, color){
    context.beginPath()
    context.moveTo(lastPosition[0], lastPosition[1]);
    context.lineTo(currentPosition[0], currentPosition[1]);
    context.strokeStyle = color
    context.stroke()
  }
  function updatePlayers(players, fillSlots=false){
    let html = Array.from(Array(6)).map((_, i) => {
      if(i < players.length){
        let player = players[i]
        return `
        <div data-index="${i}" class="shadow-lg rounded-lg bg-white border border-gray-200 m-3 w-64 h-16">
          <div class="flex items-center ml-2 mt-2">
            <div class="rounded-full w-5 h-5" style="background-color:${player.color}"></div>
            <div class="ml-2">${player.name}</div>
          </div>
          <div class="votes" style="display:flex"></div>
        </div>
        `
      }
      if(fillSlots){
        return `
          <div class="border border-dashed border-gray-500 rounded-xl m-3 w-64 h-16"></div>
        `
      }
      return ''
    }).reduce((accum, current) => accum+current)
    document.querySelectorAll(".player_slots").forEach(div => div.innerHTML = html)
  }
  canvas.addEventListener("mousedown", e => {
    if(game.players[game.player_turn].id == clientPlayer.id){
      isPainting = true
      lastPosition = [e.layerX, e.layerY]
      channel.push("mousedown", {position: lastPosition})
    }
  })
  canvas.addEventListener("mouseup", e => {
    if(isPainting){
      isPainting = false
      lastPosition = [e.layerX, e.layerY]
      channel.push("mouseup", {})
    }
  })
  canvas.addEventListener("mousemove", e => {
    if(isPainting){
      let paintedPosition = [e.layerX, e.layerY]
      paintCanvas(lastPosition, paintedPosition, clientPlayer.color)
      channel.push("draw", {position: paintedPosition})
      lastPosition = paintedPosition
    }
  })

  channel.on("player_draw", payload => {
    let paintedPosition = payload.position
    paintCanvas(lastPosition, paintedPosition, payload.player.color)
    lastPosition = paintedPosition
  })
  channel.on("player_mousedown", payload => {
    lastPosition = payload.position
  })
  channel.on("join", payload => {
    game.players = payload.players
    updatePlayers(game.players, true)
  })
  channel.on("leave", payload => {
    game.players = payload.players
    updatePlayers(game.players)
  })
  channel.on("next_turn", payload => {
    let previous_player = game.players[game.player_turn]
    game.player_turn = payload.next_player
    game.status = payload.status
    if(game.status == "voting"){
      document.querySelector("#deliberation").style.display = "block"
      document.querySelectorAll('#deliberation .player_slots > div').forEach(element => element.style.cursor = "pointer")
      document.querySelectorAll('#deliberation .player_slots > div').forEach((element, index) => element.addEventListener("click", () => {
        channel.push("vote_fake", {player_index: index})
      }))
    }
    else{
      let next_player = game.players[game.player_turn]
      console.log(payload)
      document.querySelector("#modal-message").innerHTML = `<div><b>${previous_player.name}</b> lifted the pen...</div><div style="font-size: 4rem"><b>${next_player.name}</b></div><div style="font-size: 2rem">is next!</div>`
      document.querySelector("#modal-message").style.display = "block"
      setTimeout(() => {
        document.querySelector("#modal-message").style.display = "none"
      }, 3000)
    }
  })
  channel.on("start_game", payload => {
    console.log(payload)
    game = payload
    updatePlayers(game.players)
    let is_fake_artist = game.fake_artist != null

    document.querySelector("#lobby").style.display = "none"
    document.querySelector("#game").style.display = "block"
    document.querySelector("#game #category").innerText = `Category: ${payload.word.category}`
    document.querySelector("#game #word").innerText = is_fake_artist ? "" : `Word: ${payload.word.text}`

    let fake_artist_tag = document.querySelector("#game #fake_artist")
    fake_artist_tag.style.color = is_fake_artist ? "red" : "green"
    fake_artist_tag.innerText = is_fake_artist ? "You're the fake artist" : "You're not the fake artist"
  })

  channel.on("vote_fake", payload => {
    console.log(payload)
    let votes = {}
    game.players.forEach((_, index) => {
      votes[index] = []
    })
    Object.entries(payload.votes).forEach(entry => {
      let [accusing_player_index, accused_player_index] = entry
      votes[accused_player_index].push(accusing_player_index)
    })
    Object.entries(votes).forEach(entry => {
      let accused = parseInt(entry[0])
      let votes = entry[1]
      // console.log("Me: ", clientPlayer)
      // console.log("Accused:", accused, "Votes:", votes)
      let innerHTML = votes.map(player_index => {
        let player = game.players[player_index]
        return `<div style="border-radius: 100%; width: 20px; height:20px; background-color:${player.color}"></div>`
      }).reduce((accum, current) => accum+current, '') 
      document.querySelector(`.player_slots:last-child > div:nth-child(${accused+1}) .votes`).innerHTML = innerHTML
    })
  })
  channel.on("game_over", payload => {
    game = payload
    document.querySelector("#lobby").style.display = "none"
    document.querySelector("#game").style.display = "none"
    document.querySelector("#deliberation").style.display = "none"
    let gameOverNode = document.querySelector("#game_over")
    gameOverNode.style.display = "block"
    let title = game.winner === 'real_artists' && game.fake_artist != clientPlayer.id || game.winner == "fake_artist" && game.fake_artist === clientPlayer.id ? "You Win!" : "You lose!"
    gameOverNode.innerHTML = `<h1>${title}</h1>`
  })
}
document.querySelector('input[name="name"]').addEventListener("keyup", e => {
  console.log(e)
  console.log(e.target.value)
  channel.push("change_name", e.target.value)
})
document.querySelector('#start-button').addEventListener("click", () => {
  channel.push("start_game", {})
})

