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

