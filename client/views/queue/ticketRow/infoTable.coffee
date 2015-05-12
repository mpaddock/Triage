Template.infoTable.helpers
  admin: ->
    _.contains Queues.findOne({name: @queueName})?.memberIds, Meteor.userId()
  file: ->
    FileRegistry.findOne {_id: this.valueOf()}
