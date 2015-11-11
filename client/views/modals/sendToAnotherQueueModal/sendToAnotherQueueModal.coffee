Template.sendToAnotherQueueModal.events
  'shown.bs.modal': (e, tpl) ->
    # Workaround to prevent multiple modals from hiding on ESC keypress.
    tpl.$('select').focus()

  'show.bs.modal': (e, tpl) ->
    zIndex = 1040 + ( 10 * $('.modal:visible').length)
    $(e.target).css('z-index', zIndex)
    setTimeout ->
      $('.modal-backdrop').not('.modal-stack').css('z-index',  zIndex-1).addClass('.modal-stack')
    , 10

  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view
    if $('.modal:visible').length
      $(document.body).addClass('modal-open')

  'click button[name=cancel]': (e, tpl) ->
    tpl.$('#sendToAnotherQueueModal').modal('hide')

  'click button[name=send]': (e, tpl) ->
    Tickets.update {_id: @ticketId},
      $set:
        queueName: tpl.$('select[name=queue]').val()
        status: 'Transferred'
    tpl.$('#sendToAnotherQueueModal').modal('hide')


Template.sendToAnotherQueueModal.helpers
  originalTicket: -> Tickets.findOne(@ticketId)
  queues: ->
    Queues.find
      name:
        $nin: [Tickets.findOne(@ticketId)?.queueName]

