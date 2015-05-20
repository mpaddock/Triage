Template.queuebar.helpers
  queue: ->
    #Use fetch so we get a null result if the user has access to no queues.
    Queues.find({memberIds: Meteor.userId()}).fetch()
  active: ->
    if this.name is Session.get("queueName")
      return "active"
    else
      return null
  globalClass: ->
    if Session.get('pseudoQueue') is 'globalQueue' then return 'active'
  userClass: ->
    if Session.get('pseudoQueue') is 'userQueue' then return 'active'


