if Npm.require('cluster').isMaster
  Tickets.after.update (userId, doc, fieldNames, modifier, options) ->
    console.log 'tickets after update', arguments
    _.each doc.associatedUserIds, (u) ->
      if u != userId
        console.log "alerting #{u} about updated ticket #{doc._id}"
        TicketFlags.upsert {userId: u, ticketId: doc._id, k: 'unread'},
          $set:
            v: true

  Changelog.after.insert (userId, doc) ->
    console.log 'changelog after insert', arguments
    _.each Tickets.findOne(doc.ticketId)?.associatedUserIds, (u) ->
      if u != userId
        console.log "alerting #{u} about updated ticket #{doc._id}"
        TicketFlags.upsert {userId: u, ticketId: doc.ticketId, k: 'unread'},
          $set:
            v: true

