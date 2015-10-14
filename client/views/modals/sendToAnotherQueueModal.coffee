Template.sendToAnotherQueueModal.events
  'hidden.bs.modal': (e, tpl) ->
    Blaze.remove tpl.view
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

