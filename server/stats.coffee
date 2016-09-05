Meteor.publish 'userStats', (startDate, endDate) ->
  calculateUserStats startDate, endDate
  UserStats.find { startDate: startDate, endDate: endDate }

calculateUserStats = (startDate, endDate) ->
  console.log "calculating stats between #{startDate} and #{endDate}"
  pipeline = []
  pipeline.push { $project: { 'queueName': 1, 'closedByUsername': 1, 'closedTimestamp': 1, 'timeToClose': 1 } }
  pipeline.push { $match: {
    'closedTimestamp': { $gt: startDate, $lt: endDate }
  } }
  pipeline.push { $group: {
    _id: { queueName: "$queueName", closedByUsername: "$closedByUsername" }
    count: { $sum: 1 }
    timeToClose: { $avg: "$timeToClose" }
  } }

  tickets = Tickets.aggregate(pipeline)
  _.each tickets, (t) ->
    UserStats.upsert { startDate: startDate, endDate: endDate, queueName: t._id.queueName, closedByUsername: t._id.closedByUsername },
      { $set: { timeToClose: t.timeToClose, count: t.count } }


Meteor.methods
  'getTicketsForStats': ->
    queues = _.pluck Queues.find({memberIds: @userId}).fetch(), 'name'
    console.log 'finding tickets for stats'
    t = Tickets.find({queueName: {$in: queues}},
      {fields: {
        _id: 0
        submittedTimestamp: 1
        submittedByUserId: 1
        timeToClose: 1
        closedTimestamp: 1
        closedByUsername: 1
        queueName: 1
      }, limit: 1000}).map (t) ->
        _.extend t,
          submitterDepartment: Meteor.users.findOne(t.submittedByUserId)?.department
    console.log t
    return t


Meteor.publish 'ticketStats', ->
  TicketStats.find()

aggregateTicketsByDay = ->
  TicketStats.remove({})
  submittedPipeline = []
  submittedPipeline.push { $project:
    {
      queueName: 1
      year: { $year: '$submittedTimestamp' }
      month: { $month: '$submittedTimestamp' }
      day: { $dayOfMonth: '$submittedTimestamp' }
    }
  }
  submittedPipeline.push { $group:
    {
      _id: {
        queueName: '$queueName'
        year: '$year'
        month: '$month'
        day: '$day'
      }
      submittedCount: { $sum: 1 }
    }
  }

  closedPipeline = []
  closedPipeline.push { $match: { closedTimestamp: { $exists: true } } }
  closedPipeline.push { $project:
    {
      queueName: 1
      year: { $year: '$closedTimestamp' }
      month: { $month: '$closedTimestamp' }
      day: { $dayOfMonth: '$closedTimestamp' }
    }
  }
  closedPipeline.push { $group:
    {
      _id: {
        queueName: '$queueName'
        year: '$year'
        month: '$month'
        day: '$day'
      }
      closedCount: { $sum: 1 }
    }
  }

  submitted = Tickets.aggregate(submittedPipeline)
  closed = Tickets.aggregate(closedPipeline)
  _.each submitted, (s) ->
    closedMatch = _.find(closed, (c) ->
      c._id.year is s._id.year and c._id.month is s._id.month and c._id.day is s._id.day and s._id.queueName is c._id.queueName
    )
    s.closedCount = closedMatch?.closedCount || 0
    TicketStats.upsert {
      queueName: s._id.queueName
      date: "#{s._id.year}-#{s._id.month}-#{s._id.day}"
    }, { $set: { closedCount: s.closedCount, submittedCount: s.submittedCount } }

SyncedCron.add
  name: 'Update queue submitted/closed tickets'
  schedule: (parser) -> parser.text 'every 15 minutes'
  job: ->
    aggregateTicketsByDay()

SyncedCron.start()
