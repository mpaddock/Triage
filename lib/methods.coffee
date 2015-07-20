Meteor.methods
  'setFlag': (userId, ticketId, k, v) ->
    TicketFlags.upsert {userId: userId, ticketId: ticketId, k: k}, {$set: {v: v} }
  'removeFlag': (userId, ticketId, k) ->
    TicketFlags.remove {userId: userId, ticketId: ticketId, k: k}
  'clearQueueBadge': (queueName) ->
    QueueBadgeCounts.update {queueName: queueName, userId: @userId}, {$set: {count: 0}}


(exports ? this).escape = (str) ->
  str.replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\`/g, '&#96;')
