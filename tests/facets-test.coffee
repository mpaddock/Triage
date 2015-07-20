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

# Have to tenatively drop these since $text isn't supported in Minimongo.
###
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
###
#
Tinytest.add 'Filter - verifyFilterObject', (test) ->
  test.equal Filter.verifyFilterObject(filter, ['Q', 'C', 'D'], 1), true
  test.equal Filter.verifyFilterObject(filter, ['C', 'D']), false
  test.equal Filter.verifyFilterObject(filter2, ['Q', 'C', 'D'], 1), true
  test.equal Filter.verifyFilterObject(filter2, ['C', 'D'], 1), true
  test.equal Filter.verifyFilterObject(filter2, ['Q', 'C', 'D'], 2), false
  test.equal Filter.verifyFilterObject(filter3, ['Q', 'R', 'C']), true
  test.equal Filter.verifyFilterObject(filter3, ['Q', 'C', 'D']), false

# TODO: is bidirectionality between facet string and search filter object part of our contract?
#Tinytest.add 'Filter - from/to FacetString bidirectionality', (test) ->
#  test.equal filter, Filter.fromFacetString(Filter.toFacetString(filter))

