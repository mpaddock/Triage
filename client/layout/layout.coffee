Template.layout.onCreated ->
  $(window).on 'keydown', (e) ->
    if e.keyCode is 27
        $('.modal-background').click()
