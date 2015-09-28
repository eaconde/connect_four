

ready = () ->

  String.prototype.getOrCreateStore = (defaultValue, force) ->
    force = if force == undefined then false else true
    value = localStorage.getItem(@) unless force
    if value == null || value == undefined || value == 'undefined'
      console.log "getOrCreateStore key:#{@}: returning passed data with #{defaultValue}"
      localStorage.setItem(@, defaultValue)
      return defaultValue # return default
      
    # return from storage
    console.log "getOrCreateStore key:#{@}: returning defaults with #{value}"
    return value


  class ConnectFour
    playing_as = ''
    playing_as_id = null
    playing_as_name = ''
    playing_vs = ''
    playing_vs_id = null
    playing_vs_name = ''

    # **********************************************************
    # CONSTRUCTOR
    # **********************************************************
    constructor: (gameData, player1, player2, moves, root_url) ->
      # variable assignment
      @gameData = gameData
      @player1 = player1
      @player2 = player2
      @moves = moves
      @root_url = root_url

      console.log "constructor: gameData == #{@gameData}"
      console.log "constructor: player1 == #{@player1}"
      console.log "constructor: player2 == #{@player2}"
      console.log "constructor: moves == #{@moves}"
      console.log "constructor: root_url == #{@root_url}"

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

      @p1Score = 0
      @p2Score = 0

      @gameID = gameData.id if gameData
      if player1
        console.log "assigning player1 id"
        @p1ID = player1.id
        @players.p1 = player1.id
      if player2
        @p2ID = player2.id
        @players.p2 = player2.id

      # console.log "@player1 == #{@player}"
      # restore state from given data
      @restoreGameState()


    # **********************************************************
    # FAYE SUBSCRIPTIONS
    # **********************************************************
    # Faye Client
    faye = new Faye.Client('http://faye-cedar.herokuapp.com/faye')

    # -----------------------
    # manageSubscriptions
    # -----------------------
    manageSubscriptions: ->
      console.log "manageSubscriptions: @players == #{JSON.stringify(@players)}"
      if @gameID != undefined

        console.log "subscription: /play/#{@gameID}/join"
        faye.subscribe("/play/#{@gameID}/join", (data) =>
          @player2 = 'player2'.getOrCreateStore(data.player2)
          @p2ID = @player2.id
          @players.p2 = @player2.id
          playing_vs = 'playing_vs'.getOrCreateStore('p2')
          playing_vs_id = 'playing_vs_id'.getOrCreateStore(@player2.id)
          playing_vs_name = 'playing_vs_name'.getOrCreateStore(@player2.name)

          $('#player2 p:first').text("Name: #{@player2.name}")
          $('#header h3:first').text(@gameData.title)

          @enableUI()

        )

        faye.subscribe("/play/new", (data) =>
          location.reload(true) if gon.game == undefined && window.location.href == @root_url
        )

        console.log "subscription: /play/#{@gameID}/completed"
        faye.subscribe("/play/#{@gameID}/completed", (data) =>
          console.log "display winner!"
          @updateScores(data.winner_id) if data.winner_id != playing_as_id
          @showWinnerModal(data.winner_id)
        )

        console.log "subscription: /play/#{@gameID}/turn"
        faye.subscribe("/play/#{@gameID}/turn", (moveData) =>
          if parseInt(moveData.player_id) != playing_as_id
            @processOpponentTurn(moveData)
            @moves.push moveData
            localStorage.setItem('moves', JSON.stringify(@moves))
        )

        console.log "subscription: /play/#{@gameID}/destroyed"
        faye.subscribe("/play/#{@gameID}/destroyed", (data) =>
          console.log "subscription: /play/#{@gameID}/destroyed: should have been redirected to index"
          @setVarsToPristine()

          window.location.replace(@root_url);
        )

    # -----------------------
    # setGameReset
    # -----------------------
    setGameReset: ->
      # NOTE: Only player 2 will be listening to the game reset
      #       as player 1 is responsible for trigerring the actual reset
      if (@p1ID != null && @p1ID != undefined) && (@p2ID != null && @p2ID != undefined)
        # console.log "setGameReset: /play/reset?p1=#{@p1ID}&p2=#{@p2ID}"
        console.log "setGameReset: /play/reset/#{@p1ID}/#{@p2ID}"
        faye.subscribe("/play/reset/#{@p1ID}/#{@p2ID}", (data) =>
          console.log "setGameReset: #{data}"
          $('#modal-gameover').modal('hide')
          @resetGame(data)
        )


    # **********************************************************
    # UTILITY
    # **********************************************************

    # -----------------------
    # isEmpty
    # -----------------------
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

    # -----------------------
    # enableUI
    # -----------------------
    enableUI: ->
      $('#displaybox').removeClass('overlay').addClass('hidden')
      $('#loader > i').addClass('hidden')

    # -----------------------
    # disableUI
    # -----------------------
    disableUI: ->
      $('#displaybox').removeClass('hidden').addClass('overlay')
      $('#loader > i').removeClass('hidden')

    # -----------------------
    # restoreGameState
    # -----------------------
    restoreGameState: ->
      @enableUI()
      if !@isEmpty(@gameData) && @p2ID == undefined
        # new game..."
        playing_as = 'playing_as'.getOrCreateStore('p1')
        playing_as_id = 'playing_as_id'.getOrCreateStore(@player1.id)
        playing_as_name = 'playing_as_name'.getOrCreateStore(@player1.name)

        @disableUI()
      else if !@isEmpty(@gameData) && @p2ID != undefined
        # player 2 joined
        playing_as = 'playing_as'.getOrCreateStore('p2')
        playing_as_id = 'playing_as_id'.getOrCreateStore(@player2.id)
        playing_as_name = 'playing_as_name'.getOrCreateStore(@player2.name)

        playing_vs = 'playing_vs'.getOrCreateStore('p1')
        playing_vs_id = 'playing_vs_id'.getOrCreateStore(@player1.id)
        playing_vs_name = 'playing_vs_name'.getOrCreateStore(@player1.name)

        color = @players[playing_as + '-color']
        $('#chip').css
          background: color
        $('#chip > .inner-circle').css
          background: color

        $('.modal-body > p:last').removeClass('hidden')
        $('#resetGame').prop
          'disabled': true

        @disableUI()


      if window.location.href == @root_url
        console.log "restoreGameState: INDEX #{window.location.href == @root_url}"
        @setVarsToPristine()

      @setGameReset()

    # -----------------------
    # setVarsToPristine
    # -----------------------
    setVarsToPristine: ->
      playing_as = ''
      playing_as_id = null
      playing_as_name = ''
      playing_vs = ''
      playing_vs_id = null
      playing_vs_name = ''
      @gameData = {}
      @player1 = {}
      @player2 = {}
      @moves = []
      @players.p1 = 0
      @players.p2 = 0
      @gameID = 0
      @p1ID = 0
      @p2ID = 0

      #reset
      localStorage.removeItem('gameData')
      localStorage.removeItem('player1')
      localStorage.removeItem('player2')
      localStorage.removeItem('moves')
      localStorage.removeItem('playing_as')
      localStorage.removeItem('playing_as_id')
      localStorage.removeItem('playing_as_name')
      localStorage.removeItem('playing_vs')
      localStorage.removeItem('playing_vs_id')
      localStorage.removeItem('playing_vs_name')


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
      diagonalBRtoTLWin = (pos) =>
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
    # METHODS
    # **********************************************************

    # -----------------------
    # processOpponentTurn
    # -----------------------
    processOpponentTurn: (moveData) ->
      @setMoveToUI moveData.x_pos, moveData.y_pos, playing_vs
      # gameData = gameData
      # gon.gameData = gameData
      @enableUI()

    # -----------------------
    # updateScores
    # -----------------------
    updateScores: (winner_id) ->
      # TODO: scores update
      console.log "update scores"

      @p1Score += 1 if winner_id == @player1.id
      @p2Score += 1 if winner_id == @player2.id

      $('#p1Score').text(@p1Score)
      $('#p2Score').text(@p2Score)

    # -----------------------
    # showWinnerModal
    # -----------------------
    showWinnerModal: (winner_id) ->
      player_name = if winner_id == playing_as_id then playing_as_name else playing_vs_name
      player = if winner_id == playing_as_id then playing_as else playing_vs
      color = @players[player + "-color"]
      console.log "Winner is #{player} with color #{color}!"

      $('.modal-header > i').css
        "color": color
      $('.modal-body > p:first').text("#{player_name} Wins!")
      $('.modal-body > p:first').css
        "color": color
      $('#modal-gameover').modal(
        backdrop: 'static',
        keyboard: false
      )

    # -----------------------
    # verifyGameState
    # -----------------------
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
            @updateScores(data.winner_id)
            @showWinnerModal(data.winner_id)

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
    # resetUIMove
    # -----------------------
    resetUIMove: (x_axis, y_axis) ->
      moveID = "#x#{x_axis}y#{y_axis}"

      $(moveID).css
        background: 'white'
      $(moveID).removeClass("tagged")
      $(moveID).empty()

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
          @moves = 'moves'.getOrCreateStore(@moves, true)
          # localStorage.setItem('moves', JSON.stringify(@moves))
          @setMoveToUI x_axis, y_axis, playing_as
          # switch player
          @disableUI()
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

    # -----------------------
    # resetGameUI
    # -----------------------
    resetGame: (game) ->
      @gameData = 'gameData'.getOrCreateStore(game, true)

      #reset UI
      @moves.map (move) =>
        @resetUIMove move.x_pos, move.y_pos

      @moves = 'moves'.getOrCreateStore([], true)



    # **********************************************************
    # EVENTS
    # **********************************************************
    manageEvents: ->
      $('#gameBoard').on('mousemove', (e) =>
        position = @getXPosition($('#gameBoard'), e.pageX)
        # console.log "Currently @ x: #{position}"
        $('#chip').css
          left: position
      )

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
      )

      $('#resetGame').on('click', (e) =>
        #clear vars and init new game state
        data =
          p1: @p1ID
          p2: @p2ID

        $.ajax
          method: 'POST'
          url: "reset"
          dataType: 'JSON'
          data:
            play: data
          success: (data) =>
            console.log "RESETTING GAME WITH #{data}"
            @resetGame(data)
      )

      # players > leave
      $('#leaveGame').on('click', (e) =>
        # notify opponent on leave
        $.ajax
          method: 'DELETE'
          url: "#{@gameID}"
          dataType: 'JSON'
          success: (data) =>
            # reset vars and localStorage
            @setVarsToPristine()
      )



  # **********************************************************
  # GAME INITIALIZATION
  # **********************************************************

  checkStorage = () ->
    root_url = 'root_url'.getOrCreateStore(gon.root_url)
    gameData = 'gameData'.getOrCreateStore(gon.game)
    player1 = 'player1'.getOrCreateStore(gon.player1)
    player2 = 'player2'.getOrCreateStore(gon.player2)
    moves = 'moves'.getOrCreateStore([])

    console.log "checkStorage: gameData == #{gameData} || #{gon.game}"
    console.log "checkStorage: player1 == #{player1}"
    console.log "checkStorage: player2 == #{player2}"
    console.log "checkStorage: moves == #{moves}"
    console.log "checkStorage: root_url == #{root_url}"

    vars =
      gameData: gameData
      player1: player1
      player2: player2
      moves: moves
      root_url: root_url


  vars = checkStorage()
  game = new ConnectFour(vars.gameData, vars.player1, vars.player2, vars.moves, vars.root_url)
  game.manageSubscriptions()
  game.manageEvents()


$(document).ready(ready);
$(document).on('page:load', ready);
