Template.ticketCard.events
  'click .ticket-card-body': (e, tpl) ->
    Iron.query.set 'ticket', tpl.data.ticketNumber
