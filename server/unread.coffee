if Npm.require('cluster').isMaster
  Tickets.after.update (userId, doc, fieldNames, modifier, options) ->
    _.each doc.associatedUserIds, (u) ->
      if u != userId
        TicketFlags.upsert {userId: u, ticketId: doc._id, k: 'unread'},
          $set:
            v: true

  Changelog.after.insert (userId, doc) ->
    _.each Tickets.findOne(doc.ticketId)?.associatedUserIds, (u) ->
      if u != userId
        TicketFlags.upsert {userId: u, ticketId: doc.ticketId, k: 'unread'},
          $set:
            v: true

