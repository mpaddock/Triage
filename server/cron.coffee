updateQueueStatistics = (queueName) ->
  console.log "updating statistics for queue #{queueName}"
  now = new Date()
  weekStart = new Date()
  weekStart.setDate(now.getDate() - now.getDay())
  weekStart.setHours 0
  weekStart.setMinutes 0
  weekStart.setSeconds 0
  weekStart.setMilliseconds 0
  monthAgo = new Date()
  monthAgo.setDate(now.getDate() - now.getDay() - 28)
  monthAgo.setHours 0
  monthAgo.setMinutes 0
  monthAgo.setSeconds 0
  monthAgo.setMilliseconds 0
  month = _.extend {numSubmitted: 0, avgTimeToClose: 0}, Tickets.aggregate([
    $match:
      queueName: queueName
      submittedTimestamp: {$gt: monthAgo, $lt: weekStart}
  ,
    $group:
      _id: "$queueName"
      numSubmitted:
        $sum: 1
      avgTimeToClose:
        $avg: "$timeToClose"
  ])[0]
  week = _.extend {numSubmitted: 0, avgTimeToClose: 0}, Tickets.aggregate([
    $match:
      queueName: queueName
      submittedTimestamp: $gt: new Date(weekStart)
  ,
    $group:
      _id: "$queueName"
      numSubmitted:
        $sum: 1
      avgTimeToClose:
        $avg: "$timeToClose"
  ])[0]
  weeklyLeader = _.extend {_id: '', numClosed: 0, avgTimeToClose: 0}, Tickets.aggregate([
    $match:
      queueName: queueName
      status: 'Closed'
      submittedTimestamp: $gt: new Date(weekStart)
  ,
    $group:
      _id: "$closedByUsername"
      numClosed:
        $sum: 1
      avgTimeToClose:
        $avg: "$timeToClose"
  ,
    $sort:
      numClosed: -1
  ])[0]
  weeklyLeader.username = weeklyLeader._id
  delete weeklyLeader._id
  Queues.update {name: queueName},
    $set:
      stats:
        week: week
        month: month
        weeklyLeader: weeklyLeader


SyncedCron.add
  name: 'Update queue statistics'
  schedule: (parser) -> parser.text 'every 30 seconds'
  job: ->
    Queues.find().forEach (q) ->
      updateQueueStatistics q.name

SyncedCron.start()

