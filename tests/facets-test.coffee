filter =
    queueName: 'Q'
    search: 'phrase'
    status: '!Closed'

filter2 =
  queueName: 'Q'
  userId: 1
  status: "Open"

filter3 =
  queueName: ['Q', 'R']
  status: '!Closed'

Tinytest.add 'Filter - toMongoSelector', (test) ->
  selector = Filter.toMongoSelector(filter)
  if Meteor.isServer
    test.equal selector,
      queueName: 'Q'
      $text: { '$search': 'phrase' }
      status: { '$ne': 'Closed' }

  if Meteor.isClient
    test.equal selector,
      queueName: 'Q'
      status: { '$ne': 'Closed' }

Tinytest.add 'Filter - verifyFilterObject', (test) ->
  test.equal Filter.verifyFilterObject(filter, ['Q', 'C', 'D'], 1), true
  test.equal Filter.verifyFilterObject(filter, ['C', 'D']), false
  test.equal Filter.verifyFilterObject(filter2, ['Q', 'C', 'D'], 1), true
  test.equal Filter.verifyFilterObject(filter2, ['C', 'D'], 1), true
  test.equal Filter.verifyFilterObject(filter2, ['Q', 'C', 'D'], 2), false
  test.equal Filter.verifyFilterObject(filter3, ['Q', 'R', 'C']), true
  test.equal Filter.verifyFilterObject(filter3, ['Q', 'C', 'D']), false
