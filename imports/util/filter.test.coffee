{expect} = require 'chai'
{Filter} = require './filter.coffee'

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

describe 'Filter', ->
  describe 'toMongoSelector', ->
    selector = Filter.toMongoSelector(filter)

    if Meteor.isServer
      it 'includes {$text} for full-text search on the server', ->
        expect(selector).to.deep.equal
          queueName: 'Q'
          $text: { '$search': 'phrase' }
          status: { '$ne': 'Closed' }

    if Meteor.isClient
      it 'filters to queueName and a default closed status on client', ->
        expect(selector).to.deep.equal
          queueName: 'Q'
          status: { '$ne': 'Closed' }

  it 'verifyFilterObject', ->
    expect(Filter.verifyFilterObject(filter, ['Q', 'C', 'D'], 1)).to.be.true
    expect(Filter.verifyFilterObject(filter, ['C', 'D'])).to.be.false
    expect(Filter.verifyFilterObject(filter2, ['Q', 'C', 'D'], 1)).to.be.true
    expect(Filter.verifyFilterObject(filter2, ['C', 'D'], 1)).to.be.true
    expect(Filter.verifyFilterObject(filter2, ['Q', 'C', 'D'], 2)).to.be.false
    expect(Filter.verifyFilterObject(filter3, ['Q', 'R', 'C'])).to.be.true
    expect(Filter.verifyFilterObject(filter3, ['Q', 'C', 'D'])).to.be.false

