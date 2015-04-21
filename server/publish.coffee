Meteor.publishComposite 'queuesByName', (queueName, filter, limit) ->
  check filter, Object

  mongoFilter = Filter.toMongoSelector queueName, filter
  facetPath = Filter.toFacetString queueName, filter

  {
    find: () ->
      Queues.find {name: queueName, memberIds: @userId}

    children: [
      {
        find: (queue) ->
          Facets.upsert {facet: facetPath},
            {$set: {counts: Facets.compute(queue.name, filter)}}
          cursor = Facets.find({facet: facetPath})
          cursor.observe
            removed: (oldDoc) ->
              Facets.upsert {facet: oldDoc.facet},
                {$set: {counts: Facets.compute(queue.name, filter)}}
          return cursor
      },
      {
        find: (queue) ->
          #Arbitrary maximum of 500 tickets returned at once. Maybe define this somewhere (Meteor.settings?) 
          if limit > 500 then limit = 500
          Tickets.find mongoFilter, {sort: {submittedTimestamp: -1}, limit: limit}
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
