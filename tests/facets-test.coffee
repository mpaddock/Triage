filter =
    queueName: 'Queue'
    user: undefined
    userId: undefined
    search: 'phrase'
    status: '!Closed'
    tag: undefined
    ticketNumber: '1234'

Tinytest.add 'Filter - toMongoSelector', (test) ->
  test.equal Filter.toMongoSelector(filter),
    queueName: 'Queue'
    '$and': [
      '$or': [{title: {}}, {body: {}}]
    ],
    status: { '$ne': 'Closed' },
    ticketNumber: 1234

Tinytest.add 'Filter - toFacetString', (test) ->
  test.equal Filter.toFacetString(filter),
    "queueName:Queue|search:phrase|status:!Closed"


# TODO: is bidirectionality between facet string and search filter object part of our contract?
Tinytest.add 'Filter - from/to FacetString bidirectionality', (test) ->
  test.equal filter, Filter.fromFacetString(Filter.toFacetString(filter))

