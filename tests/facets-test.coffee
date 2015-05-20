filter =
    queueName: 'Q'
    search: 'phrase'
    status: '!Closed'

Tinytest.add 'Filter - toMongoSelector', (test) ->
  selector = Filter.toMongoSelector(filter)
  test.equal selector,
    queueName: 'Q'
    '$and': [
      '$or': [{title: {}}, {body: {}}]
    ],
    status: { '$ne': 'Closed' },

  shouldMatch = [
    {queueName: 'Q', title: 'phrase can be in the title'},
    {queueName: 'Q', body: 'phrase can be in the body'},
    {queueName: 'Q', body: 'even capitalized Phrase should match'}
  ]

  _.each shouldMatch, (d) ->
    test.equal true, new Minimongo.Matcher(selector).documentMatches(d).result

  shouldNotMatch = [
    {queueName: 'Q', title: 'word'},
    {queueName: 'Q', body: 'text'},
    {queueName: 'Q2', title: 'phrase'},
    {queueName: 'Q', title: 'phrase', status: 'Closed'}
  ]

  _.each shouldNotMatch, (d) ->
    test.equal false, new Minimongo.Matcher(selector).documentMatches(d).result

Tinytest.add 'Filter - toFacetString', (test) ->
  test.equal Filter.toFacetString(filter),
    "queueName:Q|search:phrase|status:!Closed"

# TODO: is bidirectionality between facet string and search filter object part of our contract?
Tinytest.add 'Filter - from/to FacetString bidirectionality', (test) ->
  test.equal filter, Filter.fromFacetString(Filter.toFacetString(filter))

