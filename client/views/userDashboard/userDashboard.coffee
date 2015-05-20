Template.userDashboard.helpers
  queue: ->
    Queues.find({memberIds: Meteor.userId()}).fetch()
        
