Router.configure
  layoutTemplate: 'layout'

Router.onBeforeAction () ->
  if @ready()
    if not Meteor.userId()
      @render('login')
    else
      @next()

Router.map ->
  @route 'tickets',
    path: '/'

  @route 'queue',
    path: '/queue/:queue_name',
    onBeforeAction: ->
      Session.set "queueName", @params.queue_name #just makes it easier for our sidebar. can't get data context to work at the moment.
      @next()
    data: -> Tickets.find {queueName: @params.queue_name}
    
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

