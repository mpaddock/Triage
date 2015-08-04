Migrations.add
  version: 1
  up: ->
    Tickets.update({associatedUserIds: { $exists: false } }, {$set: { associatedUserIds: [] } }, {multi: true} )

Meteor.startup ->
  Migrations.migrateTo(1)
