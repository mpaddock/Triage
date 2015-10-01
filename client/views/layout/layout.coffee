Template.layout.onCreated ->
  $(window).on 'keydown', (e) ->
    if e.keyCode is 27
      maxZ = 0
      $modal = null
      $('.modal:visible').each ->
        curZ = $(this).css('z-index')
        if curZ >= maxZ
          maxZ = curZ
          $modal = $(this)
      setTimeout ->
        $modal.modal('hide')
      , 10
