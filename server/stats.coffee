Meteor.methods
  'getTicketsForStats': ->
    queues = _.pluck Queues.find({memberIds: @userId}).fetch(), 'name'
    console.log 'finding tickets for stats'
    t = Tickets.find({queueName: {$in: queues}, closedTimestamp: { $exists: true } },
      {fields: {
        _id: 0
        submittedTimestamp: 1
        submittedByUserId: 1
        timeToClose: 1
        closedTimestamp: 1
        closedByUsername: 1
        queueName: 1
      }}).map (t) ->
        _.extend t,
          submitterDepartment: Meteor.users.findOne(t.submittedByUserId)?.department
    return t
