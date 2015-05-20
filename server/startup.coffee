Meteor.startup ->
  Meteor.settings.queues.forEach (x) ->
    Queues.upsert {name: x.name}, {$set: {securityGroups: x.securityGroups}}
