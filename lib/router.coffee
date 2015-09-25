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
      queue = Meteor.user()?.defaultQueue || Queues.findOne({memberIds: Meteor.userId()})?.name
      if queue
        @redirect '/queue/'+queue
      else
        @redirect '/my/tickets'

  @route 'queue',
    path: '/queue/:queueName',
    onBeforeAction: ->
      Session.set 'ready', false
      Session.set 'loadingMore', false
      Session.set 'pseudoQueue', null
      Session.set 'queueName', @params.queueName
      Session.set 'newTicketSet', []
      Session.set 'offset', (Number(Iron.query.get('start')) || 0)
      @next()
      if Meteor.userId()
        filter =
          queueName: @params.queueName
          search: @params.query.search
          status: @params.query.status || '!Closed'
          tag: @params.query.tag
          user: @params.query.user
          associatedUser: @params.query.associatedUser
        
        if Session.get('offset') < 1
          renderedTime = new Date()
          Meteor.subscribe 'newTickets', filter, renderedTime
        queueName = @params.queueName
        Meteor.subscribe 'tickets', filter, Session.get('offset'), limit, onReady: () ->
          Meteor.call 'clearQueueBadge', queueName
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
      Session.set 'newTicketSet', []
      Session.set 'offset', (Number(Iron.query.get('start')) || 0)
      @next()
      if Meteor.userId()
        filter =
          queueName: _.pluck(Queues.find().fetch(), 'name')
          search: @params.query.search
          status: @params.query.status || '!Closed'
          tag: @params.query.tag
          user: @params.query.user
          associatedUser: @params.query.associatedUser
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
      Session.set 'newTicketSet', []
      Session.set 'offset', (Number(Iron.query.get('start')) || 0)
      @next()
      if Meteor.userId()
        filter =
          queueName: _.pluck(Queues.find({memberIds: Meteor.userId()}).fetch(), 'name')
          search: @params.query.search
          status: @params.query.status || '!Closed'
          tag: @params.query.tag
          user: @params.query.user
          associatedUser: @params.query.associatedUser

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
      requiredParams = ['username', 'email', 'description', 'queueName']
      for k in requiredParams
        if not @request.body[k]? then throw new Meteor.Error 412, "Missing required parameter #{k} in request."

      Meteor.call 'checkUsername', @request.body.username


      blackboxKeys = _.difference(_.keys(@request.body), requiredParams.concat(['submitter_name', 'subject_line', 'on_behalf_of'], Tickets.simpleSchema()._schemaKeys))
      formFields = _.pick(@request.body, blackboxKeys)
      username = /// \b#{@request.body.username}\b ///i

      ticket =
        title: @request.body.subject_line
        body: @request.body.description
        authorName: @request.body.username.toLowerCase()
        authorId: Meteor.users.findOne({username: username})._id
        submissionData:
          method: 'Form'
          ipAddress: @request.body.ip_address
          hostname: @request.body.hostname? @request.body.ip_address
        submittedTimestamp: Date.now()
        queueName: @request.body.queueName || 'Triage'
        tags: @request.body.tags?.split(';\n') || []
        formFields: formFields
        attachmentIds: _.pluck(@request.files, '_id')

      if @request.body.on_behalf_of?.length
        ticket.formFields['Submitted by'] = ticket.authorName
        ticket.formFields['On behalf of'] = @request.body.on_behalf_of
        behalfOfId = Meteor.call 'checkUsername', @request.body.on_behalf_of
        if behalfOfId
          ticket.submittedByUserId = ticket.authorId
          ticket.authorName = @request.body.on_behalf_of.toLowerCase()
          ticket.authorId = behalfOfId

      Tickets.insert ticket

      @response.end 'Submission successful.'

  @route 'serveFile',
    path: '/file/:filename'
    where: 'server'
    action: FileRegistry.serveFile

