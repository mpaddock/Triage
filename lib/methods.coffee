Meteor.methods
  'setFlag': (userId, ticketId, k, v) ->
    TicketFlags.upsert {userId: userId, ticketId: ticketId, k: k}, {$set: {v: v} }
  'removeFlag': (userId, ticketId, k) ->
    TicketFlags.remove {userId: userId, ticketId: ticketId, k: k}
  'clearQueueBadge': (queueName) ->
    QueueBadgeCounts.update {queueName: queueName, userId: @userId}, {$set: {count: 0}}
