Meteor.publishComposite 'queuesByUser',
  find: () ->
    sgs = Meteor.users.findOne({_id: @userId}).memberOf.map (x) ->
      return new RegExp(x.substr(3, x.indexOf(',')-3), "i")
    return Queues.find {securityGroups: {$in: sgs}}

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
Meteor.publish 'allUserData', () ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1}}

Meteor.publish 'queueNames', () ->
  Queues.find {}, {fields: {'name': 1}}
