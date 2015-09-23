

$ ->
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
  turn = 'p1'

  if gon.game
    gameID = gon.game.gameID
    p1ID = gon.game.p1
    p2ID = gon.game.p2
    gameData = gon.game

  players =
    'p1': p1ID
    'p1-color': 'red'
    'p2': p2ID
    'p2-color': 'yellow'

  faye = new Faye.Client('http://faye-cedar.herokuapp.com/faye');
  faye.subscribe("/player/join", (data) ->
    console.log "data from realtime == #{data}"
    # updateLayout
    # allowTurns
  )

  # =============================================
  # METHODS
  # =============================================

  # setMove
  # -----------------------
  setMoveToUI = (x_axis, y_axis) ->
    moveID = "#x#{x_axis}y#{y_axis}"
    console.log "setting move #{moveID}"
    $(moveID).css
      background: players[turn + '-color']

  # updateMoveState
  updateMoveState = () ->
    turn = if turn == 'p1' then 'p2' else 'p1'
    console.log "NEXT TURN #{turn}"

    $('#chip').css('background', players[turn + '-color'])


  # getY
  # -----------------------
  getY = (x_axis) ->
    y_axis = 0
    for y in [0..6]
      result = moves.filter (value) ->
        return value if value['x'] == x_axis && value['y'] == y

      if result.length == 0
        y_axis = y
        break

    return y_axis

  # makeMove
  # -----------------------
  makeMove = (x_axis) ->
    y_axis = getY(x_axis)
    playerID = players[turn]
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
        console.log "data == #{JSON.stringify(data)}"
        moves.push
          'x': x_axis
          'y': y_axis
          'turn': 'p1'

        setMoveToUI x_axis, y_axis
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
    # allowance = $('#moveBox').css('margin-left')
    # allowance = allowance.replace(/px/g, '')
    # position = getXPosition($('#gameBoard'))
    x_axis = getXPosition($('#gameBoard'), e.pageX) #e.clientX - allowance #- 100

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
    # switch player


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

  return;
