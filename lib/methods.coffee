Meteor.methods
  'setFlag': (userId, ticketId, k, v) ->
    TicketFlags.upsert {userId: userId, ticketId: ticketId, k: k}, {$set: {v: v} }


  'updateStatus': (userId, ticketId, status) ->
    Tickets.update {_id: ticketId}, {$set: {status: status}}
    username = Meteor.users.findOne({_id: userId}).username
    Changelog.insert {ticketId: ticketId, timestamp: new Date(), authorId: userId, authorName: username, type: 'field', field: 'status', message: "status changed to #{status}"}
    #TODO: Send an email?

