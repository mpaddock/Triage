@Facets = new Mongo.Collection 'facets'
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

@Filter =
  toMongoSelector: (queueName, filter) ->
    check queueName, String
    check filter, Object

    mongoFilter = queueName: queueName
    if filter.search?.trim().length
      mongoFilter['$or'] = [
        { title: new RegExp(filter.search.replace(',','|'), 'i') },
        { body: new RegExp(filter.search.replace(',','|'), 'i') }
      ]
    if filter.status?
      mongoFilter.status = filter.status || ''
    if filter.tag?
      tags = filter.tag.split(',')
      sorted = _.sortBy(tags).join(',')
      mongoFilter.tags = {$all: tags}
    return mongoFilter

  toFacetString: (queueName, filter) ->
    check queueName, String
    check filter, Object

    facetPath = "queueName:#{queueName}"
    if filter.search?.trim().length
      facetPath += "|search:#{filter.search}"
    if filter.status?.trim().length
      facetPath += "|status:#{filter.status}"
    if filter.tag?.length
      sortedTags = _.sortBy(filter.tag.split(',')).join(',')
      facetPath += "tags:#{sortedTags}"
    return facetPath

  fromFacetString: (facetString) ->
    check facetString, String
    filter =
      queueName: ''
      search: ''
      status: ''
      tags: []
    for f in facetString.split('|')
      f = f.split(':')
      if f[0] is 'tags'
        filter[f[0]] = f[1].split(',')
      else
        filter[f[0]] = f[1]
    return filter

if Meteor.isServer
  Meteor.startup ->
    if Npm.require('cluster').isMaster
      ready = false
      refreshFacetQueues = (queues) ->
        if ready
          Facets.remove facet: $in: _.map queues, (q) ->
            new RegExp "^queueName:#{q}"
          console.log 'forcing recreation of facets for', queues
      Tickets.find({},{fields:{queueName:1,status:1,tags:1}}).observe
        added: (doc) ->
          refreshFacetQueues doc.queueName
        changed: (newDoc, oldDoc) ->
          refreshFacetQueues _.union newDoc.queueName, oldDoc.queueName
        removed: (oldDoc) ->
          refreshFacetQueues oldDoc.queueName
      ready = true
  @Facets.compute = (queueName, filter) ->
    check queueName, String
    check filter, Object

    facets = {}
    match = Filter.toMongoSelector queueName, filter

    facets.status = _.map Tickets.aggregate([
      {$match: match},
      {$group: {_id: "$status", count: {$sum: 1}}}
    ]), (s) -> {name: s._id, count: s.count}

    facets.tags = _.map Tickets.aggregate([
      {$match: match},
      {$unwind: "$tags"},
      {$group: {_id: "$tags", count: {$sum: 1}}}
    ]), (s) -> {name: s._id, count: s.count}

    return facets

