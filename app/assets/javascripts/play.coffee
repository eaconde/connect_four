

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

  x_tiles =
    x0: '', x1: '', x2: '', x3: '', x4: '', x5: '', x6: ''
  y_tiles =
    x0: '', x1: '', x2: '', x3: '', x4: '', x5: ''

  # { x: 0, y: 0, move: 'p1' }
  moves = []

  # =============================================
  # METHODS
  # =============================================

  getY = (x_axis) ->
    y_axis = 0
    for y in [0..6]
      result = moves.filter (value) ->
        return value if value['x'] == x_axis && value['y'] == y

      if result.length == 0
        y_axis = y
        break

    y_axis


  makeMove = (x_axis) ->
    y_axis = getY(x_axis)
    
    moves.push
      'x': x_axis,
      'y': y_axis,
      'turn': 'p1'

  # =============================================
  # EVENTS
  # =============================================
  $('#moveBox').on('mousemove', (e) ->
    # TODO: implement limiting on x overlaps
    $('#chip').css
      left:  e.clientX - 25
  );

  $('#moveBox').on('click', (e) ->
    allowance = $('#moveBox').css('margin-left')
    allowance = allowance.replace(/px/g, '')
    x_axis = e.clientX - allowance + 10

    # based on x axis, allot player move
    limit = Object.keys(x_axis_limits).length - 1
    x_pos = -1

    for i in [0..limit]
      c = 'x' + i
      n = 'x' + (i+1)

      if i == 0 && x_axis <= x_axis_limits[c]
        x_pos = 0
        break
      else if x_axis > x_axis_limits[c] && x_axis <= x_axis_limits[n]
        x_pos = i
        break
      else if i == limit
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
