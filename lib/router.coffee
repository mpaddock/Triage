Router.configure
  layoutTemplate: 'layout'

Router.map ->
  @route 'tickets',
    path: '/'

  @route 'queue',
    path: '/queue/:queue_name',
    onBeforeAction: ->
      Session.set "queueName", @params.queue_name #just makes it easier for our sidebar. can't get data context to work at the moment.
      @next()
    data: -> Tickets.find {queueName: @params.queue_name}
    

