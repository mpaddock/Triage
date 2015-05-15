filter =
    queueName: 'Queue'
    user: undefined
    userId: undefined
    search: 'phrase'
    status: '!Closed'
    tag: undefined
    ticketNumber: '1234'

Tinytest.add 'Filter - toMongoSelector', (test) ->
  test.equal Filter.toMongoSelector(filter), {}

Tinytest.add 'Filter - toFacetString', (test) ->
  test.equal 1,2

Tinytest.add 'Filter - fromFacetString', (test) ->
  test.equal 1,2

