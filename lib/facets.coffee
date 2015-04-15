@Facets = new Mongo.Collection 'facets'
@Facets._createCappedCollection 16*1024*1024, 1000
@Facets.attachSchema new SimpleSchema
  facet:
    type: String
    unique: true
    index: 1
  'counts.status':
    type: [Object]
  'counts.status.$.name':
    type: String
  'counts.status.$.count':
    type: Number
  'counts.tags':
    type: [Object]
  'counts.tags.$.name':
    type: String
  'counts.tags.$.count':
    type: Number

if Meteor.isServer
  ComputeFacets = (queueName, search, status, tags) ->
    check queueName, String
    check search, String
    check status, String
    check tags, Array

    facets = {}

    facets.status = _.map Tickets.aggregate([
      {$match: {queueName: queueName}},
      {$group: {_id: "$status", count: {$sum: 1}}}
    ]), (s) -> {name: s._id, count: s.count}

    facets.tags = _.map Tickets.aggregate([
      {$match: {queueName: queueName}},
      {$unwind: "$tags"},
      {$group: {_id: "$tags", count: {$sum: 1}}}
    ]), (s) -> {name: s._id, count: s.count}

    return facets


  Meteor.startup ->
    console.log 'Recomputing facets...'
    @Queues.find().forEach (q) ->
      console.log "Top level facet for queue #{q.name}..."
      console.log ComputeFacets q.name, '', '', []

