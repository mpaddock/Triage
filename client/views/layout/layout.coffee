Template.layout.onCreated ->
  $(window).on 'keydown', (e) ->
    if e.keyCode is 27
      if $('#attachmentModal').length
        console.log 'attachmentModal'
        $('#attachmentModal').modal('hide')
      else
        $('#ticketModal').modal('hide')
        $('#newTicketModal').modal('hide')
