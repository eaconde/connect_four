$ ->
  console.log("DOM is ready")


  $('#moveBox').on('mousemove', (e) ->
    console.log 'mousemoved!!!'
    $('#chip').css
      left:  e.clientX - 25;
  );
