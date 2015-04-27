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
      queue = Meteor.user().defaultQueue? || Queues.findOne().name
      @redirect '/queue/'+queue

  @route 'queue',
    path: '/queue/:queueName',
    onBeforeAction: ->
      Session.set 'limit', 30
      Session.set 'queueName', @params.queueName #just makes it easier for our sidebar. can't get data context to work at the moment.
      @next()
      if Meteor.userId()
        [Meteor.subscribe 'queuesByName', @params.queueName, {
          search: Iron.query.get 'search'
          status: Iron.query.get 'status'
          tag: Iron.query.get 'tag'
        }, 30]


  @route 'queueDashboard',
    path: '/queue/:queueName/dashboard',
    onBeforeAction: ->
      Session.set 'queueName', @params.queueName #Temporary until we figure out how we're storing queues probably.
      @next()

  @route 'userDashboard',
    path: '/my/dashboard'

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

