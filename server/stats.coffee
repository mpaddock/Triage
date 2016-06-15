Meteor.publish 'stats', (startDate, endDate) ->
  calculateStats startDate, endDate
  Stats.find { startDate: startDate, endDate: endDate }

calculateStats = (startDate, endDate) ->
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
    Stats.upsert { startDate: startDate, endDate: endDate, queueName: t._id.queueName, closedByUsername: t._id.closedByUsername },
      { $set: { timeToClose: t.timeToClose, count: t.count } }

