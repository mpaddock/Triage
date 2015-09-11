Template.queueSummary.helpers
  data: ->
    d = Queues.findOne {name: Session.get 'queueName'}
    console.log 'queueSummary data', d
    return d
  elapsed: (s) ->
    moment.utc(s*1000).format('HH:mm:ss')
###
  month: ->
    numSubmitted: (->
      now = new Date()
      monthAgo = new Date().setDate(now.getDate() - 28)
      Tickets.find({queueName: Session.get('queueName'),  timestamp: {$gt: monthAgo}}).count())()
  week: ->
    numSubmitted: (->
      now = new Date()
      weekStart = new Date().setDate(now.getDate() - now.getDay())
      Tickets.find({queueName: Session.get('queueName'), timestamp: {$gt: weekStart}}).count())()
    avgTimeToClose: 'test'
  weeklyLeader: ->
    username: 'nmad222'
    avgTimeToClose: '5 seconds'
###

