Migrations.add
  version: 1
  up: ->
    Tickets.update({associatedUserIds: { $exists: false } }, {$set: { associatedUserIds: [] } }, {multi: true} )

Migrations.add
  version: 2
  up: ->
    _.each Tickets.find().fetch(), (doc) ->
      author = Meteor.users.findOne(doc.authorId)
      Tickets.update doc._id, { $addToSet: { additionalText: { $each: [ author?.displayName, author?.department ] } } }

Migrations.add
  version: 3
  up: ->
    _.each Tickets.find({timeToClose: {$exists: true}, closedTimestamp: {$exists: false}}).fetch(), (doc) ->
      Tickets.update doc._id,
        $set:
          closedTimestamp: new Date(doc.submittedTimestamp.getTime() + doc.timeToClose*1000)

Migrations.add
  version: 4
  up: ->
    _.each Tickets.find().fetch(), (doc) ->
      Tickets.direct.update doc._id, { $addToSet: { additionalText: doc.ticketNumber.toString() } }

Migrations.add
  version: 5
  up: ->
    Tickets.find().forEach (doc) ->
      Tickets.direct.update doc._id,
        $set:
          lastUpdated: Changelog.findOne(ticketId: doc._id, {sort: {timestamp: -1}})?.timestamp || doc.submittedTimestamp

Meteor.startup ->
  Migrations.migrateTo(5)
