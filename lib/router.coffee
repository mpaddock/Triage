limit = Meteor.settings.public?.pageLimit || 20
offset = Meteor.settings.public?.offset || 20

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
      Session.set 'pseudoQueue', null
      Session.set 'queueName', @params.queueName
      Session.set 'newTickets', []
      Session.set 'offset', (Number(Iron.query.get('start')) || 0)
      @next()
      if Meteor.userId()
        filter =
          queueName: @params.queueName
          search: @params.query.search
          status: @params.query.status || '!Closed'
          tag: @params.query.tag
          user: @params.query.user
        
        if Session.get('offset') < 1
          renderedTime = new Date()
          Meteor.subscribe 'newTickets', filter, renderedTime
        Meteor.subscribe 'tickets', filter, Session.get('offset'), limit, onReady: () ->
          Session.set('ready', true)
        

  @route 'userDashboard',
    path: '/my/dashboard'
    onBeforeAction: ->
      Session.set 'queueName', null
      Session.set 'pseudoQueue', null
      @next()

  @route 'userQueue',
    path: '/my/tickets'
    template: 'queue'
    waitOn: ->
      Meteor.subscribe 'queueNames'
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'loadingMore', false
      Session.set 'queueName', null
      Session.set 'pseudoQueue', 'userQueue'
      Session.set 'newTickets', []
      Session.set 'offset', (Number(Iron.query.get('start')) || 0)
      @next()
      if Meteor.userId()
        filter =
          queueName: _.pluck(Queues.find().fetch(), 'name')
          search: @params.query.search
          status: @params.query.status || '!Closed'
          tag: @params.query.tag
          user: @params.query.user
          userId: Meteor.userId()
        if Session.get('offset') < 1
          renderedTime = new Date()
          Meteor.subscribe 'newTickets', filter, renderedTime
        Meteor.subscribe 'tickets', filter, Session.get('offset'), limit, onReady: () ->
          Session.set('ready', true)
        

  @route 'globalQueue',
    path: '/all/tickets'
    template: 'queue'
    waitOn: ->
      Meteor.subscribe 'queueNames'
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'loadingMore', false
      Session.set 'queueName', null
      Session.set 'pseudoQueue', 'globalQueue'
      Session.set 'newTickets', []
      Session.set 'offset', (Number(Iron.query.get('start')) || 0)
      @next()
      if Meteor.userId()
        filter =
          queueName: _.pluck(Queues.find({memberIds: Meteor.userId()}).fetch(), 'name')
          search: @params.query.search
          status: @params.query.status || '!Closed'
          tag: @params.query.tag
          user: @params.query.user

        if Session.get('offset') < 1
          renderedTime = new Date()
          Meteor.subscribe 'newTickets', filter, renderedTime

        Meteor.subscribe 'tickets', filter, Session.get('offset'), limit, onReady: () ->
          Session.set('ready', true)
        

  @route 'ticket',
    path: '/ticket/:ticketNumber'
    template: 'ticket'
    onBeforeAction: ->
      Session.set 'ticketNumber', Number(@params.ticketNumber)
      @next()
      if Meteor.userId()
        Meteor.subscribe 'ticket', Number(@params.ticketNumber)


  @route 'apiSubmit',
    path: '/api/1.0/submit'
    where: 'server'
    action: ->
      # TODO: check X-Auth-Token header
      unless @request.headers['x-forwarded-for'] in Meteor.settings?.remoteWhitelist
        console.log 'API submit request from '+@request.headers['x-forwarded-for']+' not in API whitelist'
        throw new Meteor.Error 403,
          'Access denied.  Submit from a whitelisted IP address or use an API token.'

      console.log @request.body
      for k in ['username', 'email', 'description', 'ip_address', 'queueName']
        if not @request.body[k]? then throw new Meteor.Error 412, "Missing required parameter #{k} in request."

      Meteor.call 'checkUsername', @request.body.username

      Tickets.insert
        title: @request.body.subject_line
        body: @request.body.description
        authorName: @request.body.username
        authorId: Meteor.users.findOne({username: @request.body.username})._id
        submissionData:
          method: 'Web'
          ipAddress: @request.body.ip_address
          hostname: @request.body.hostname? @request.body.ip_address
        submittedTimestamp: Date.now()
        queueName: @request.body.queueName || 'Triage'
        tags: @request.body.tags?.split(';\n') || []

      @response.end 'Submission successful.'

  @route 'serveFile',
    path: '/file/:filename'
    where: 'server'
    action: FileRegistry.serveFile

