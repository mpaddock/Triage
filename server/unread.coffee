if Npm.require('cluster').isMaster
  Tickets.after.update (userId, doc, fieldNames, modifier, options) ->
    if doc.authorId != userId
      TicketFlags.upsert {userId: doc.authorId, ticketId: doc._id, k: 'unread'},
        $set:
          v: true
    _.each doc.associatedUserIds, (u) ->
      if u != userId
        TicketFlags.upsert {userId: u, ticketId: doc._id, k: 'unread'},
          $set:
            v: true

  Changelog.after.insert (userId, doc) ->
    ticket = Tickets.findOne(doc.ticketId)
    if ticket?.authorId != userId
      TicketFlags.upsert {userId: ticket.authorId, ticketId: doc.ticketId, k: 'unread'},
        $set:
          v: true
    _.each ticket?.associatedUserIds, (u) ->
      if u != userId
        TicketFlags.upsert {userId: u, ticketId: doc.ticketId, k: 'unread'},
          $set:
            v: true

