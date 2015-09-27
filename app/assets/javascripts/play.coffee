

ready = () ->
  class ConnectFour
    playing_as = ''
    playing_as_id = null
    playing_as_name = ''
    playing_vs = ''
    playing_vs_id = null
    playing_vs_name = ''

    # ==========================================
    # CONSTRUCTOR
    # ==========================================
    constructor: (gameData, player1, player2, moves) ->
      # variable assignment
      @gameData = gameData
      @player1 = player1
      @player2 = player2
      @moves = moves

      console.log "constructor: gameData == #{@gameData}"
      console.log "constructor: player1 == #{@player1}"
      console.log "constructor: player2 == #{@player2}"
      console.log "constructor: moves == #{@moves}"

      # set defaults
      @x_axis_limits =
        x0: 50,
        x1: 100,
        x2: 150,
        x3: 200,
        x4: 250,
        x5: 300,
        x6: 350
      @players =
        p1: 0,
        'p1-color': '#d9534f',
        p2: 0,
        'p2-color': '#cfeb22'

      @gameID = gameData.id if gameData
      if player1
        @p1ID = player1.id
        @players.p1 = player1.id
      if player2
        @p2ID = player2.id
        @players.p2 = player2.id


      # restore state from given data
      @restoreGameState()


    # **********************************************************
    # FAYE SUBSCRIPTIONS
    # **********************************************************
    manageSubscriptions: ->
      # Faye Client
      faye = new Faye.Client('http://faye-cedar.herokuapp.com/faye');
      console.log "manageSubscriptions: @players == #{JSON.stringify(@players)}"
      if @gameID != undefined
        console.log "subscription: /play/#{@gameID}/join"
        faye.subscribe("/play/#{@gameID}/join", (data) =>
          @player2 = data.player2
          localStorage.setItem('player2', JSON.stringify(@player2))
          localStorage.setItem('playing_vs', 'p2')
          localStorage.setItem('playing_vs_id', @player2.id)
          localStorage.setItem('playing_vs_name', @player2.name)

          @p2ID = @player2.id
          @players.p2 = @player2.id
          playing_vs = localStorage.getItem('playing_vs')
          playing_vs_id = localStorage.getItem('playing_vs_id')
          playing_vs_name = localStorage.getItem('playing_vs_name')

          console.log "AFTER PLAYER 2 JOINED == #{@player2}"

          $('#player2 p:first').text("Name: #{@player2.name}")
          $('#header h3:first').text(@gameData.title)

          @enableUI()
        )

        faye.subscribe("/play/new", (data) =>
          location.reload(true) if gon.game == undefined && window.location.href == root_url
        )

        console.log "subscription: /play/#{@gameID}/completed"
        faye.subscribe("/play/#{@gameID}/completed", (data) =>
          console.log "display winner!"
          @setEndUI(data.winner_id)
        )

        console.log "subscription: /game/#{@gameID}/turn"
        faye.subscribe("/game/#{@gameID}/turn", (moveData) =>
          if parseInt(moveData.player_id) != playing_as_id
            @processOpponentTurn(moveData)
            @moves.push moveData
            localStorage.setItem('moves', JSON.stringify(@moves))
        )


    # **********************************************************
    # FAYE SUBSCRIPTIONS END
    # **********************************************************


    # =============================================
    # UTILITY
    # =============================================

    isEmpty: (obj) ->
      return true if obj == null || obj == undefined

      # Assume if it has a length property with a non-zero value
      # that that property is correct.
      return false if obj.length > 0
      return true if obj.length == 0

      # Otherwise, does it have any properties of its own?
      # Note that this doesn't handle
      # toString and valueOf enumeration bugs in IE < 9
      for key of obj
        return false if (hasOwnProperty.call(obj, key))

      return true


    enableUI: ->
      $('#displaybox').removeClass('overlay').addClass('hidden')
      $('#loader > i').addClass('hidden')


    disableUI: ->
      $('#displaybox').removeClass('hidden').addClass('overlay')
      $('#loader > i').removeClass('hidden')


    restoreGameState: ->
      if !@isEmpty(@gameData) && @p2ID == undefined
        console.log "Setting vars from localStorage"
        # new game..."
        playing_as = localStorage.getItem('playing_as')
        if playing_as == null
          localStorage.setItem('playing_as', 'p1')
          playing_as = 'p1'

        playing_as_id = localStorage.getItem('playing_as_id')
        if playing_as_id == null
          localStorage.setItem('playing_as_id', @player1.id)
          playing_as_id = @player1.id

        playing_as_name = localStorage.getItem('playing_as_name')
        if playing_as_name == null
          localStorage.setItem('playing_as_name', @player1.name)
          playing_as_name = @player1.name

        @disableUI()
      else if !@isEmpty(@gameData) && @p2ID != undefined
        playing_as = localStorage.getItem('playing_as')
        if playing_as == null
          localStorage.setItem('playing_as', 'p2')
          playing_as = 'p2'

        playing_as_id = localStorage.getItem('playing_as_id')
        if playing_as_id == null
          localStorage.setItem('playing_as_id', @player2.id)
          playing_as_id = @player2.id

        playing_as_name = localStorage.getItem('playing_as_name')
        if playing_as_name == null
          localStorage.setItem('playing_as_name', @player2.name)
          playing_as_name = @player2.name

        playing_vs = localStorage.getItem('playing_vs')
        if playing_vs == null
          localStorage.setItem('playing_vs', 'p1')
          playing_vs = 'p1'

        playing_vs_id = localStorage.getItem('playing_vs_id')
        if playing_vs_id == null
          localStorage.setItem('playing_vs_id', @player1.id)
          playing_vs_id = @player1.id

        playing_vs_name = localStorage.getItem('playing_vs_name')
        if playing_vs_name == null
          localStorage.setItem('playing_vs_name', @player1.name)
          playing_vs_name = @player1.name

        color = @players[playing_as + '-color']
        $('#chip').css
          background: color
        $('#chip > .inner-circle').css
          background: color

        @disableUI()


    # **********************************************************
    # WINNER VERIFICATION - START
    # **********************************************************

    # -----------------------
    # horizontalWin
    # -----------------------
    horizontalWin: (pos) ->
      # fixed Y position only
      y = parseInt(pos.y_pos)
      pID = pos.player_id
      matchCtr = 0
      console.log "horizontalWin for #{y} @ #{pID}"
      for ctr in [0..6]
        result = @moves.filter (move) ->
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
    verticalWin: (pos) ->
      # fixed X position only
      x = parseInt(pos.x_pos)
      pID = pos.player_id
      matchCtr = 0
      for ctr in [0..5]
        result = @moves.filter (move) ->
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
    diagonalWin: (pos) ->

      # -----------------------
      # getStartingXY
      # -----------------------
      getStartingXY = (pos, direction) =>
        result =
          x_pos: 0,
          y_pos: 0

        startX = pos.x_pos
        startY = pos.y_pos
        if direction == 'ltr'
          while startX >= 0 || startY >= 0
            startX -= 1
            startY -= 1
        else
          while startX <= 6 || startY >= 0
            startX += 1
            startY -= 1

        result.x_pos = startX
        result.y_pos = startY
        result

      # -----------------------
      # diagonalBLtoTRWin
      # bottom left to top right
      # -----------------------
      diagonalBLtoTRWin = (pos) =>
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
          # console.log "returning from diagonalBLtoTRWin due to match = #{JSON.stringify(match)}"
          return false

        matchCtr = 0
        startXY = getStartingXY(pos, 'ltr')
        startX = startXY.x_pos
        startY = startXY.y_pos
        player_id = pos.player_id

        while startX <= 6 || startY <= 5
          match = @moves.filter (move) ->
            return move.x_pos == startX && move.y_pos == startY && move.player_id == player_id

          if match.length == 1
            matchCtr += 1
          else
            matchCtr = 0

          return true if matchCtr == 4

          startX += 1
          startY += 1

        return false


      # -----------------------
      # diagonalBRtoTLWin
      # bottom right to top left
      # -----------------------
      diagonalBRtoTLWin = (pos) ->
        exclude =
          [
            { x: 0, y: 0 },
            { x: 0, y: 1 },
            { x: 0, y: 2 },
            { x: 1, y: 0 },
            { x: 1, y: 1 },
            { x: 2, y: 0 },
            { x: 4, y: 5 },
            { x: 5, y: 4 },
            { x: 5, y: 5 },
            { x: 6, y: 3 },
            { x: 6, y: 4 },
            { x: 6, y: 5 }
          ]
        match = exclude.filter (elem) ->
          return elem.x == pos.x_pos && elem.y == pos.y_pos
        if match.length == 1
          return false

        matchCtr = 0
        startXY = getStartingXY(pos, 'rtl')
        startX = startXY.x_pos
        startY = startXY.y_pos
        player_id = pos.player_id


        while startX >= 0 || startY <= 5
          match = @moves.filter (move) ->
            return move.x_pos == startX && move.y_pos == startY && move.player_id == player_id

          if match.length == 1
            matchCtr += 1
          else
            matchCtr = 0

          return true if matchCtr == 4

          startX -= 1
          startY += 1

        return false

      diagonalBLtoTRWin(pos) || diagonalBRtoTLWin(pos)

    # -----------------------
    # diagonalWin - END
    # -----------------------

    # -----------------------
    # checkWinner
    # -----------------------
    checkWinner: (pos) ->
      return true if @horizontalWin(pos)
      return true if @verticalWin(pos)
      return true if @diagonalWin(pos)

    # -----------------------
    # checkTie
    # -----------------------

    # **********************************************************
    # WINNER VERIFICATION - END
    # **********************************************************

    # =============================================
    # METHODS
    # =============================================

    processOpponentTurn: (moveData) ->
      @setMoveToUI moveData.x_pos, moveData.y_pos, playing_vs
      # gameData = gameData
      # gon.gameData = gameData
      @enableUI()

    updateScores: (winner_id) ->
      # TODO: scores update
      console.log "update scores"

    showWinnerModal: (winner_id) ->
      player_name = if winner_id == playing_as_id then playing_as_name else playing_vs_name
      player = if winner_id == playing_as_id then playing_as else playing_vs
      color = @players[player + "-color"]
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

    setEndUI: (winner_id) ->
      @updateScores(winner_id)
      @showWinnerModal(winner_id)

    verifyGameState: (pos) ->
      # TODO: handle draw
      if @checkWinner(pos)
        data =
          winner_id: pos.player_id
        $.ajax
          method: 'PUT'
          url: "#{@gameID}/complete"
          dataType: 'JSON'
          data:
            play: data
          success: (data) =>
            console.log "GAME OVER"
            @setEndUI(data.winner_id)


    # -----------------------
    # setMoveToUI
    # -----------------------
    setMoveToUI: (x_axis, y_axis, pmove) ->
      moveID = "#x#{x_axis}y#{y_axis}"
      color = @players[pmove + '-color']
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
    updateMoveState: ->
      @disableUI()


    # -----------------------
    # makeMove
    # -----------------------
    makeMove: (x_axis) ->
      # -----------------------
      # getY
      # -----------------------
      getY = (x_axis) =>
        y_axis = 0
        for y in [0..6]
          result = @moves.filter (move) ->
            if parseInt(move.x_pos) == x_axis && parseInt(move.y_pos) == y
              return move

          if result.length == 0
            y_axis = y
            break

        return y_axis

      y_axis = getY(x_axis)
      playerID = @players[playing_as]
      moveData =
        game_id: @gameID
        x_pos: x_axis
        y_pos: y_axis
        player_id: playerID

      $.ajax
        method: 'POST'
        url: "#{@gameID}/moves"
        dataType: 'JSON'
        data:
          move: moveData
        success: (data) =>
          @moves.push data
          localStorage.setItem('moves', JSON.stringify(@moves))
          @setMoveToUI x_axis, y_axis, playing_as
          # switch player
          @updateMoveState()
          @verifyGameState(data)

    # -----------------------
    # getXPosition
    # -----------------------
    getXPosition: (element, cursorLoc) ->
      allowance = $('#chip').css('width').replace(/px/g, '') / 2
      positionX = cursorLoc - element.position().left - allowance
      width = element.css('width').replace(/px/g, '') - $('#chip').css('width').replace(/px/g, '')

      positionX = if positionX < 0 then 0 else positionX
      positionX = if positionX > width then width else positionX

    # =============================================
    # EVENTS
    # =============================================
    manageEvents: ->
      $('#gameBoard').on('mousemove', (e) =>
        position = @getXPosition($('#gameBoard'), e.pageX)
        # console.log "Currently @ x: #{position}"
        $('#chip').css
          left: position
      );

      $('#gameBoard').on('click', (e) =>
        x_axis = @getXPosition($('#gameBoard'), e.pageX)

        # based on x axis, allot player move
        limit = Object.keys(@x_axis_limits).length - 1
        x_pos = -1

        for i in [0..limit]
          pad = 7 * i
          c = 'x' + i
          n = 'x' + (i + 1)
          x_curr = @x_axis_limits[c]+pad
          x_next = @x_axis_limits[n]+pad || x_axis

          if x_curr > x_axis && x_axis <= x_next
            x_pos = i
            break

        @makeMove(x_pos)

      );


  # ====================
  # initialize game data either from API or localStorage
  # ====================
  checkStorage = () ->
    # set gameData
    localStorage.setItem('gameData', [])
    gameData = localStorage.getItem('gameData')
    if gameData.length == 0
      gameData = gon.game
      localStorage.setItem('gameData', JSON.stringify(gameData))
    else
      gameData = JSON.parseJSON(gameData)

    # set player1
    localStorage.setItem('player1', [])
    player1 = localStorage.getItem('player1')
    if player1.length == 0
      player1 = gon.player1
      localStorage.setItem('player1', JSON.stringify(player1))
    else
      player1 = JSON.parseJSON(player1)

    # set player2
    localStorage.setItem('player2', [])
    player2 = localStorage.getItem('player2')
    if player2.length == 0
      if gon.player2
        player2 = gon.player2
        localStorage.setItem('player2', JSON.stringify(player2))
    else
      player2 = JSON.parseJSON(player2)

    # set moves
    localStorage.setItem('moves', [])
    moves = localStorage.getItem('moves')
    if moves.length == 0
      moves = []
    else
      console.log "exising game moves! #{JSON.stringify(moves)}"
      moves = JSON.parseJSON(moves)



    vars =
      gameData: gameData
      player1: player1
      player2: player2
      moves: moves


  vars = checkStorage()
  game = new ConnectFour(vars.gameData, vars.player1, vars.player2, vars.moves)
  game.manageSubscriptions()
  game.manageEvents()


$(document).ready(ready);
$(document).on('page:load', ready);
