@Tags = new Mongo.Collection 'tags'
@Tags.attachSchema new SimpleSchema
  name:
    type: String
    unique: true
  lastUse:
    type: new Date()


if Meteor.isServer
  Meteor.startup ->
    Tickets.find({},{fields:{tags:1}}).observe
      added: (doc) ->
        doc.tags?.forEach (x) ->
          Tags.upsert {name: x}, {$set: {lastUse: new Date()}}
      changed: (doc) ->
        doc.tags?.forEach (x) ->
          Tags.upsert {name: x}, {$set: {lastUse: new Date()}}

