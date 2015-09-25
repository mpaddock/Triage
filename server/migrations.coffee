Migrations.add
  version: 1
  up: ->
    Tickets.update({associatedUserIds: { $exists: false } }, {$set: { associatedUserIds: [] } }, {multi: true} )

Migrations.add
  version: 2
  up: ->
    _.each Tickets.find().fetch(), (doc) ->
      author = Meteor.users.findOne(doc.authorId)
      Job.push new TextAggregateJob
        ticketId: doc._id
        text: [ author?.displayName, author?.department]

Meteor.startup ->
  Migrations.migrateTo(2)
