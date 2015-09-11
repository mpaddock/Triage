Template.layout.onCreated ->
  $(window).on 'keydown', (e) ->
    if e.keyCode is 27
      $('#ticketModal').modal('hide')
      $('#newTicketModal').modal('hide')
