

ready = () ->
  # =============================================
  # VARIABLES
  # =============================================
  x_axis_limits =
    x0: 50,
    x1: 100,
    x2: 150,
    x3: 200,
    x4: 250,
    x5: 300,
    x6: 350


  moves = []
  playing_as = ''
  playing_as_id = 0
  playing_as_name = ''
  playing_vs = ''
  playing_vs_id = 0
  playing_vs_name = ''

  games = gon.games
  root_url = gon.root_url
  if gon.game
    gameData = gon.game
    gameID = gon.game.id
    p1ID = gon.game.p1
    p2ID = gon.game.p2
    player1 = gon.player1
    player2 = gon.player2 if gon.player2

  players =
    'p1': p1ID
    'p1-color': '#d9534f'
    'p2': p2ID
    'p2-color': '#cfeb22'


  # **********************************************************
  # FAYE SUBSCRIPTIONS
  # **********************************************************

  # Faye Client
  faye = new Faye.Client('http://faye-cedar.herokuapp.com/faye');

  faye.subscribe("/play/#{gameID}/join", (data) ->
    player1 = data.player1
    player2 = data.player2
    gameData = data.game

    p2ID = player2.id
    playing_vs_id = p2ID
    playing_as_name = player1.name
    playing_vs_name = player2.name
    gon.player2 = player2
    gon.gameData = gameData

    console.log "AFTER PLAYER 2 JOINDED == #{gon.player2}"

    enableUI()

    $('#player2 p:first').text("Name: #{player2.name}")
    $('#header h3:first').text(gameData.title)
  )


  faye.subscribe("/play/new", (data) ->
    location.reload(true) if gon.game == undefined && window.location.href == root_url
  )

  faye.subscribe("/play/#{gameID}/completed", (data) ->
    console.log "display winner!"
    setEndUI(data.winner_id)
  )

  subscribeForTurns = () ->
    if gameID != undefined
      faye.subscribe("/game/#{gameID}/turn", (moveData) ->
        if parseInt(moveData.player_id) != playing_as_id
          processOpponentTurn(moveData)
          moves.push moveData
      )

  # **********************************************************
  # FAYE SUBSCRIPTIONS END
  # **********************************************************

  # =============================================
  # UTILITY
  # =============================================

  enableUI = () ->
    $('#displaybox').removeClass('overlay').addClass('hidden')
    $('#loader > i').addClass('hidden')

  disableUI = () ->
    $('#displaybox').removeClass('hidden').addClass('overlay')
    $('#loader > i').removeClass('hidden')



  # **********************************************************
  # WINNER VERIFICATION - START
  # **********************************************************

  # -----------------------
  # horizontalWin
  # -----------------------
  horizontalWin = (pos) ->
    # fixed Y position only
    y = parseInt(pos.y_pos)
    pID = pos.player_id
    matchCtr = 0
    console.log "horizontalWin for #{y} @ #{pID}"
    for ctr in [0..6]
      result = moves.filter (move) ->
        return (parseInt(move.y_pos) == y && parseInt(move.x_pos) == ctr && move.player_id == pID)

      if result.length == 1
        matchCtr += 1
        return true if matchCtr == 4
      else
        matchCtr = 0

    return false

  # -----------------------
  # verticalWin
  # -----------------------
  verticalWin = (pos) ->
    # fixed X position only
    x = parseInt(pos.x_pos)
    pID = pos.player_id
    matchCtr = 0
    for ctr in [0..5]
      result = moves.filter (move) ->
        # capture move if exist
        return (parseInt(move.y_pos) == ctr && parseInt(move.x_pos) == x && move.player_id == pID)

      if result.length == 1
        matchCtr += 1
        return true if matchCtr == 4
      else
        matchCtr = 0

    return false

  # -----------------------
  # diagonalWin
  # -----------------------
  diagonalWin = (pos) ->
    diagonalBLtoTRWin(pos) || diagonalBRtoTLWin(pos)


  getStartingXY = (pos) ->
    result =
      x_pos: 0,
      y_pos: 0

    startX = pos.x_pos
    startY = pos.y_pos

    while startX >= 0 || startY >= 0
      startX -= 1
      startY -= 1

    result.x_pos = startX
    result.y_pos = startY
    result

  # -----------------------
  # diagonalBLtoTRWin
  # bottom left to top right
  # -----------------------
  diagonalBLtoTRWin = (pos) ->
    exclude =
      [
        { x: 4, y: 0 },
        { x: 5, y: 0 },
        { x: 5, y: 1 },
        { x: 6, y: 0 },
        { x: 6, y: 1 },
        { x: 6, y: 2 },
        { x: 0, y: 4 },
        { x: 1, y: 5 },
        { x: 2, y: 6 },
        { x: 0, y: 5 },
        { x: 1, y: 6 },
        { x: 0, y: 6 }
      ]
    match = exclude.filter (elem) ->
      return elem.x == pos.x_pos && elem.y == pos.y_pos

    if match.length == 1
      console.log "returning from diagonalBLtoTRWin due to match = #{JSON.stringify(match)}"
      return false

    matchCtr = 0
    startXY = getStartingXY(pos)
    startX = startXY.x_pos
    startY = startXY.y_pos
    player_id = pos.player_id

    while startX <= 6 || startY <= 5
      match = moves.filter (move) ->
        return move.x_pos == startX && move.y_pos == startY && move.player_id == player_id

      if match.length == 1
        matchCtr += 1
        console.log "matchCtr = #{matchCtr}. MATCH @ #{startX}:#{startY}"
      else
        matchCtr = 0
        console.log "REST matchCtr!!!"

      return true if matchCtr == 4

      startX += 1
      startY += 1

    return false


  # -----------------------
  # diagonalRtoLWin
  # -----------------------
  # diagonalBRtoTLWin = (pos) ->
  #   exclude =
  #     [
  #       { x: 0, y: 0 },
  #       { x: 0, y: 1 },
  #       { x: 0, y: 2 },
  #       { x: 1, y: 0 },
  #       { x: 1, y: 1 },
  #       { x: 2, y: 0 }
  #     ]
  #   match = exclude.filter (elem) ->
  #     return elem.x == pos.x_pos && elem.y == pos.y_pos
  #   return false if match
  #   console.log "diagonalBRtoTLWin exclusions #{JSON.stringify(exclude)}"
    # # bottom right to top left
    false

  # -----------------------
  # checkWinner
  # -----------------------
  checkWinner = (pos) ->
    horizontalWin(pos) || verticalWin(pos) || diagonalWin(pos)

  # -----------------------
  # checkTie
  # -----------------------

  # **********************************************************
  # WINNER VERIFICATION - END
  # **********************************************************

  # =============================================
  # METHODS
  # =============================================

  processOpponentTurn = (moveData) ->
    setMoveToUI moveData.x_pos, moveData.y_pos, playing_vs
    gameData = gameData
    gon.gameData = gameData
    enableUI()

  updateScores = (winner_id) ->
    console.log "update scores"

  showWinnerModal = (winner_id) ->
    player_name = if winner_id == playing_as_id then playing_as_name else playing_vs_name
    player = if winner_id == playing_as_id then playing_as else playing_vs
    color = players[player + "-color"]
    console.log "Winner is #{player} with color #{color}!"

    $('.modal-header > i').css
      "color": color
    $('.modal-body > p').text("#{player_name} Wins!")
    $('.modal-body > p').css
      "color": color
    $('#modal-gameover').modal(
      backdrop: 'static',
      keyboard: false
    )

  setEndUI = (winner_id) ->
    updateScores(winner_id)
    showWinnerModal(winner_id)

  verifyGameState = (pos) ->
    # TODO: handle draw
    if checkWinner(pos)
      data =
        winner_id: pos.player_id
      $.ajax
        method: 'PUT'
        url: "#{gameID}/complete"
        dataType: 'JSON'
        data:
          play: data
        success: (data) =>
          console.log "GAME OVER"
          setEndUI(data.winner_id)


  # -----------------------
  # setMoveToUI
  # -----------------------
  setMoveToUI = (x_axis, y_axis, pmove) ->
    moveID = "#x#{x_axis}y#{y_axis}"
    color = players[pmove + '-color']
    console.log "setting color for #{pmove}"
    $(moveID).css
      background: color
    $(moveID).addClass("tagged")
    innerCircle = $( ".inner-circle" ).clone().removeClass('hidden')
    innerCircle.css
      background: color
    innerCircle.appendTo(moveID)



  # -----------------------
  # updateMoveState
  # -----------------------
  updateMoveState = () ->
    disableUI()

  # -----------------------
  # getY
  # -----------------------
  getY = (x_axis) ->
    y_axis = 0
    for y in [0..6]
      result = moves.filter (move) ->
        if parseInt(move.x_pos) == x_axis && parseInt(move.y_pos) == y
          return move

      if result.length == 0
        y_axis = y
        break

    return y_axis

  # -----------------------
  # makeMove
  # -----------------------
  makeMove = (x_axis) ->
    y_axis = getY(x_axis)
    playerID = players[playing_as]
    moveData =
      game_id: gameID
      x_pos: x_axis
      y_pos: y_axis
      player_id: playerID

    $.ajax
      method: 'POST'
      url: "#{gameID}/moves"
      dataType: 'JSON'
      data:
        move: moveData
      success: (data) =>
        moves.push data
        setMoveToUI x_axis, y_axis, playing_as
        # switch player
        updateMoveState()
        verifyGameState(data)



  # -----------------------
  # getXPosition
  # -----------------------
  getXPosition = (element, cursorLoc) ->
    allowance = $('#chip').css('width').replace(/px/g, '') / 2
    positionX = cursorLoc - element.position().left - allowance
    width = element.css('width').replace(/px/g, '') - $('#chip').css('width').replace(/px/g, '')

    positionX = if positionX < 0 then 0 else positionX
    positionX = if positionX > width then width else positionX

  # =============================================
  # EVENTS
  # =============================================

  $('#gameBoard').on('mousemove', (e) ->
    position = getXPosition($('#gameBoard'), e.pageX)
    console.log "Currently @ x: #{position}"
    $('#chip').css
      left: position
  );

  $('#gameBoard').on('click', (e) ->
    x_axis = getXPosition($('#gameBoard'), e.pageX)

    # based on x axis, allot player move
    limit = Object.keys(x_axis_limits).length - 1
    x_pos = -1

    for i in [0..limit]
      pad = 7 * i
      c = 'x' + i
      n = 'x' + (i + 1)
      x_curr = x_axis_limits[c]+pad
      x_next = x_axis_limits[n]+pad || x_axis

      if x_curr > x_axis && x_axis <= x_next
        x_pos = i
        break

    makeMove(x_pos)


    # # TODO: animate chip
    # bottom = $('#boxes').position().top+$('#boxes').outerHeight(true)
    # $('#chip').hide()
    # # set starting position first
    # $('#chip2').css
    #   # 'top': '100px',
    #   'left': '3px'
    # # start animation
    # $('#chip2').animate {
    #     # 'left': '0px';
    #     'top': bottom + 'px'
    #   }, 3000, ->
    #     $('#chip').show()
    #     # $('#overlay').fadeOut('fast');

  );


  do ->
    subscribeForTurns()
    if gameData == undefined
      # in index page
      enableUI()
    else if (typeof p2ID == 'undefined' || p2ID == null)
      # New game
      playing_as = 'p1'
      playing_vs = 'p2'
      playing_as_id = p1ID
      $('#displaybox').removeClass().addClass('overlay')
      console.log "JS LOADED!"
    else
      # Set p2 specific vars
      playing_as = 'p2'
      playing_vs = 'p1'
      playing_as_id = p2ID
      playing_vs_id = p1ID
      playing_as_name = player2.name
      playing_vs_name = player1.name
      color = players[playing_as + '-color']
      $('#chip').css
        background: color;
      $('#chip > .inner-circle').css
        background: color;
      # P1 Turn
      disableUI()

  return;

$(document).ready(ready);
$(document).on('page:load', ready);
