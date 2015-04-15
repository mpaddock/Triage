Meteor.publishComposite 'queuesByName', (queueName, limit) ->
  {
    find: () ->
      Queues.find {name: queueName, memberIds: @userId}

    children: [
      {
        find: (queue) ->
          facet = queue.name
          Facets.upsert {facet: facet},
            {$set: {counts: Facets.compute(queue.name, '', '', [])}}

          Facets.find {facet: queue.name}
      },
      {
        find: (queue) ->
          #Arbitrary maximum of 500 tickets returned at once. Maybe define this somewhere (Meteor.settings?) 
          if limit > 500 then limit = 500
          Tickets.find {queueName: queue.name}, {sort: {submittedTimestamp: -1}, limit: limit}
        children: [
          {
            find: (ticket) ->
              Changelog.find {ticketId: ticket._id}
          },
          {
            find: (ticket) ->
              TicketFlags.find {ticketId: ticket._id, userId: @userId}
          },
          {
            find: (ticket) ->
              if ticket.attachmentIds?.length > 0
                FileRegistry.find {_id: {$in: ticket.attachmentIds}}
          }
        ]
      }
    ]
  }

Meteor.publish 'userData', () ->
  Meteor.users.find {_id: @userId}
Meteor.publish 'allUserData', () ->
  Meteor.users.find {}, {fields: {'_id': 1, 'username': 1, 'mail': 1, 'displayName': 1, 'department': 1}}

Meteor.publish 'queueNames', () ->
  #Consider only publishing memberIds for queues that the uesr is a member of. Probably not a huge deal. 
  Queues.find {}, {fields: {'name': 1, 'memberIds': 1}}
