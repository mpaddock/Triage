limitDefault = 20

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
    waitOn: -> Meteor.subscribe 'userData'
    action: ->
      queue = Meteor.user()?.defaultQueue || Queues.findOne({memberIds: Meteor.userId()}).name
      @redirect '/queue/'+queue

  @route 'queue',
    path: '/queue/:queueName',
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'loadingMore', false
      Session.set 'limit', limitDefault
      Session.set 'pseudoQueue', null
      Session.set 'queueName', @params.queueName
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'tickets', {
          queueName: @params.queueName
          search: Iron.query.get 'search'
          status: Iron.query.get 'status'
          tag: Iron.query.get 'tag'
          user: Iron.query.get 'user'
        }, limitDefault, onReady: () ->
          Session.set('ready', true)
        ]

  @route 'userDashboard',
    path: '/my/dashboard'
    onBeforeAction: ->
      Session.set 'queueName', null
      Session.set 'pseudoQueue', null
      @next()

  @route 'userQueue',
    path: '/my/tickets'
    template: 'queue'
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'loadingMore', false
      Session.set 'limit', limitDefault
      Session.set 'queueName', null
      Session.set 'pseudoQueue', 'userQueue'
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'tickets', {
          search: Iron.query.get 'search'
          status: Iron.query.get 'status'
          tag: Iron.query.get 'tag'
          user: Iron.query.get 'user'
        }, limitDefault, true, onReady: () ->
          Session.set('ready', true)
        ]

  @route 'globalQueue',
    path: '/all/tickets'
    template: 'queue'
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'limit', limitDefault
      Session.set 'loadingMore', false
      Session.set 'queueName', null
      Session.set 'pseudoQueue', 'globalQueue'
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'tickets', {
          search: Iron.query.get 'search'
          status: Iron.query.get 'status'
          tag: Iron.query.get 'tag'
          user: Iron.query.get 'user'
        }, limitDefault, onReady: () ->
          Session.set('ready', true)
        ]

  @route 'ticket',
    path: '/ticket/:ticketNumber'
    template: 'ticket'
    onBeforeAction: ->
      Session.set 'ticketNumber', Number(@params.ticketNumber)
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'ticket', Number(@params.ticketNumber)]


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

