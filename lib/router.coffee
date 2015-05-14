Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'
  onBeforeAction: ->
    if Meteor.isClient and not Meteor.userId()
      @render 'login'
    else
      @next()

Router.map ->
  @route 'default',
    path: '/'
    action: ->
      queue = Meteor.user().defaultQueue? || Queues.findOne({memberIds: Meteor.userId()}).name
      @redirect '/queue/'+queue

  @route 'queue',
    path: '/queue/:queueName',
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'limit', 30
      Session.set 'queueName', @params.queueName
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'tickets', {
          queueName: @params.queueName
          search: Iron.query.get 'search'
          status: Iron.query.get 'status'
          tag: Iron.query.get 'tag'
          user: Iron.query.get 'user'
        }, 30, onReady: () ->
          Session.set('ready', true)
        ]

  @route 'userDashboard',
    path: '/my/dashboard'

  @route 'userQueue',
    path: '/my/tickets'
    template: 'queue'
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'queueName', 'userQueue'
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'tickets', {
          search: Iron.query.get 'search'
          status: Iron.query.get 'status'
          tag: Iron.query.get 'tag'
          user: Iron.query.get 'user'
        }, 30, true, onReady: () ->
          Session.set('ready', true)
        ]

  @route 'globalQueue',
    path: '/all/tickets'
    template: 'queue'
    onBeforeAction: ->
      Session.set 'queueName', 'globalQueue'
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'tickets', {
          search: Iron.query.get 'search'
          status: Iron.query.get 'status'
          tag: Iron.query.get 'tag'
          user: Iron.query.get 'user'
        }, 30, onReady: () ->
          Session.set('ready', true)
        ]

  @route 'ticket',
    path: '/ticket/:ticketNumber'
    template: 'ticket'
    onBeforeAction: ->
      Session.set 'ticketNumber', Number(@params.ticketNumber)
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'tickets', {
          ticketNumber: @params.ticketNumber
        }]


  @route 'apiSubmit',
    path: '/api/1.0/submit'
    where: 'server'
    action: ->
      # TODO: check IP whitelist
      # TODO: check X-Auth-Token header

      throw new Meteor.Error 403,
        'Access denied.  Submit from a whitelisted IP address or use an API token.'

      _.each ['username', 'email', 'description', 'ip_address'], (k) ->
        if not @request.params.k? then throw new Meteor.Error 412, "Missing required parameter #{k} in request."

      Tickets.insert
        title: @request.params.description.substr 0, 60 # TODO: better summarizer
        body: @request.params.description
        authorId: Meteor.users.findOne({username: @request.params.username})._id
        submissionData:
          method: 'Web'
          ipAddress: @request.params.ip_address
          hostname: @request.params.hostname? @request.params.ip_address
        submittedTimestamp: Date.now()
        queueName: 'Triage'
        tags: @request.params.tags?.split(';\n') || []

      @response.end 'Submission successful.'

  @route 'serveFile',
    path: '/file/:filename'
    where: 'server'
    action: FileRegistry.serveFile

