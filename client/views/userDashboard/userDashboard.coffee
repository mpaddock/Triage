Template.userDashboard.helpers
  queue: ->
    Queues.find().fetch()
        
