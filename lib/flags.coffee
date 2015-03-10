Meteor.methods
  'setFlag': (userId, ticketId, k, v) ->
    TicketFlags.upsert {userId: userId, ticketId: ticketId, k: k}, {$set: {v: v} }

