Template.queue.helpers
  queueAdmin: -> true #Defined queue administrators can set members of the queue (and other things, possibly)
  members: -> Queues.findOne({name: Session.get("queueName")}).memberIds
  queueName: -> Session.get "queueName"
  tickets: -> Tickets.find {queueName: Session.get("queueName")}, {sort: {submittedTimestamp: -1}}

Template.queue.rendered = () ->
  $('[data-toggle=popover]').popover()
  $(window).scroll () ->
    if $(window).scrollTop() + $(window).height() is $(document).height()
      console.log "bottom"
      Session.set 'limit', Session.get('limit') + 30

Template.queue.created = () ->
  Session.setDefault 'limit', 30
  Deps.autorun () ->
    Meteor.subscribe 'queuesByName', Session.get('queueName'), Session.get('limit')
