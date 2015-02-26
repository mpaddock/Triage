Router.configure
  layoutTemplate: 'layout'

Router.map ->
  @route 'tickets',
    path: '/'

  @route 'queue',
    path: '/queue/:queue_name',
    data: -> Tickets.find {queue: @params.queue_name}

