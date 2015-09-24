

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
    x5: 300


  moves = []
  playing_as = ''
  playing_as_id = 0
  playing_vs = ''
  playing_vs_id = 0

  if gon.game
    gameID = gon.game.id
    p1ID = gon.game.p1
    p2ID = gon.game.p2
    player1 = gon.player1
    gameData = gon.game

  players =
    'p1': p1ID
    'p1-color': '#d9534f'
    'p2': p2ID
    'p2-color': '#cfeb22'

  faye = new Faye.Client('http://faye-cedar.herokuapp.com/faye');

  faye.subscribe("/player/join", (data) ->
    player1 = data.player1
    player2 = data.player2
    gameData = data.game

    p2ID = player2.id
    playing_vs_id = p2ID
    gon.player2 = player2
    gon.gameData = gameData

    enableUI()

    $('#player2 p:first').text("Name: #{player2.name}")
    $('#header h3:first').text(gameData.title)
  )

  subscribe = () ->
    if gameID != undefined
      faye.subscribe("/game/#{gameID}/turn", (moveData) ->
        # console.log "processing from faye... #{moveData.player_id != playing_as_id} >> #{moveData.player_id} << #{playing_as_id}"
        processOpponentTurn(moveData) if moveData.player_id != playing_as_id
        moves.push moveData
      )

  processOpponentTurn = (moveData) ->
    setMoveToUI moveData.x_pos, moveData.y_pos, playing_vs
    console.log "setting move by #{moveData.player_id} to X:#{moveData.x_pos} and Y:#{moveData.y_pos}"
    gameData = gameData
    gon.gameData = gameData
    enableUI()

  # =============================================
  # UTILITY
  # =============================================

  enableUI = () ->
    $('#displaybox').removeClass('overlay').addClass('hidden')
    $('.fa').addClass('hidden')

  disableUI = () ->
    $('#displaybox').removeClass('hidden').addClass('overlay')
    $('.fa').removeClass('hidden')



  # =============================================
  # METHODS
  # =============================================

  # setMove
  # -----------------------
  setMoveToUI = (x_axis, y_axis, pmove) ->
    pmove = if (pmove == undefined) then playing_as else pmove
    moveID = "#x#{x_axis}y#{y_axis}"
    $(moveID).css
      background: players[pmove + '-color']

  # updateMoveState
  updateMoveState = () ->
    disableUI()


  # getY
  # -----------------------
  getY = (x_axis) ->
    console.log "GETTING Y for X:#{typeof x_axis}"
    y_axis = 0
    for y in [0..6]
      result = moves.filter (move) ->
        console.log "MOVE IS === #{JSON.stringify(move)} || #{typeof move.x_pos} <<>> #{typeof move.y_pos} || #{typeof y}"
        if parseInt(move.x_pos) == x_axis && parseInt(move.y_pos) == y
          console.log "RETURNING MOVE! #{move}"
          return move

      if result.length == 0
        y_axis = y
        break

    return y_axis

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

    $('#chip').css
      left: position
  );

  $('#gameBoard').on('click', (e) ->
    x_axis = getXPosition($('#gameBoard'), e.pageX)

    # based on x axis, allot player move
    limit = Object.keys(x_axis_limits).length - 1
    x_pos = -1

    for i in [0..limit]
      pad = 13*i
      c = 'x' + i
      n = 'x' + (i+1)
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
    # console.log "#|| #{(typeof p2ID == 'undefined' || p2ID == null) && gameData != undefined}"
    subscribe()
    if gameData == undefined
      enableUI()
    else if (typeof p2ID == 'undefined' || p2ID == null)
      # New game
      playing_as = 'p1'
      playing_vs = 'p2'
      playing_as_id = p1ID
      $('#displaybox').removeClass().addClass('overlay')
    else
      # Set p2 specific vars
      playing_as = 'p2'
      playing_vs = 'p1'
      playing_as_id = p2ID
      playing_vs_id = p1ID
      console.log "playing as #{playing_as} with color #{players[playing_as + '-color']}"
      $('#chip').css
        background: players[playing_as + '-color']; #+ ' !important'
        # P1 Turn
        disableUI()

  return;

$(document).ready(ready);
$(document).on('page:load', ready);
