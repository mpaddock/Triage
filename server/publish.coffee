Meteor.publishComposite 'queuesByUser',
  find: () ->
    Queues.find {memberIds: @userId}

  children: [
    {
      find: (queue) ->
        Tickets.find {queueName: queue.name}
      children: [
        {
          find: (ticket) ->
            Changelog.find {ticketId: ticket._id}
        },
        {
          find: (ticket) ->
            TicketFlags.find {ticketId: ticket._id, userId: @userId}
        }
      ]
    }
  ]

Meteor.publish 'userData', () ->
  Meteor.users.find {_id: @userId}
Meteor.publish 'allUserData', () ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1}}

Meteor.publish 'queueNames', () ->
  Queues.find {}, {fields: {'name': 1}}
