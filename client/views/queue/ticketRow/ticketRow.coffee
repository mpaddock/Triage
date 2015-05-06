Template.ticketRow.events
  ### Events for ticket status changes. ###
  'click .ticket-row': (e) ->
    collapsing = $(e.currentTarget).next().find('.accordion-body').attr('aria-expanded')
    $('html, body').clearQueue()
    if collapsing is 'true'
      $('html, body').animate({scrollTop: $(e.currentTarget).offset().top - $(window).height()/2}, 600)
    else
      target = $(e.currentTarget)
      Meteor.setTimeout ->
        $('html, body').animate({scrollTop: target.offset().top}, 375)
      , 200
  'click .dropdown-menu[name=statusMenu]': (e, tpl) ->
    e.stopPropagation() #Stops table row expanding on dropdown click. Have to trigger dropdown manually below.
  'click .dropdown-menu[name=statusMenu] a': (e, tpl) ->
    Meteor.call 'updateStatus', Meteor.userId(), this._id, $(e.target).html()
    tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')

  'keyup input[name=customStatus]': (e, tpl) ->
    if e.which is 13
      Meteor.call 'updateStatus', Meteor.userId(), this._id, e.target.value
      $(e.target).val("")
      tpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')
    
  ### Assigning users to tickets. ###
  'keyup input[name=assignUser]': (e, tpl) ->
    if e.which is 13
      id = Meteor.call 'checkUsername', e.target.value, (err, res) ->
        if res
          tpl.$('[data-toggle="tooltip"]').tooltip('hide')
          Tickets.update tpl.data._id, {$addToSet: {associatedUserIds: res}}
          $(e.target).val('')
        else
          tpl.$('[data-toggle="tooltip"]').tooltip('show')

  ### Uploading files. ###
  'click a[data-action=uploadFile]': (e, tpl) ->
    Media.pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Tickets.update tpl.data._id, {$addToSet: {attachmentIds: fileId}}
      Meteor.call 'setFlag', Meteor.userId(), tpl.data._id, 'attachment', true
      Changelog.insert
        ticketId: tpl.data._id
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "attachment"
        message: "added file " + FileRegistry.findOne({_id: fileId})?.filename
        otherId: fileId

  ### Adding notes to tickets. ###
  'keyup input[name=newNote]': (e, tpl) ->
    if (e.which is 13) and (e.target.value isnt "")
      body = e.target.value
      hashtags = getTags body
      users = getUsers body
      status = getStatuses body
      if status?.length > 0
        Tickets.update tpl.data._id, {$set: {status: status[0]}} #If multiple results, just use the first.

      if users?.length > 0
        Tickets.update tpl.data._id, {$addToSet: {associatedUserIds: $each: users}}

      if hashtags?.length > 0
        Tickets.update tpl.data._id, {$addToSet: {tags: $each: hashtags}}

      Changelog.insert
        ticketId: tpl.data._id
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "note"
        message: e.target.value

      Meteor.call 'setFlag', Meteor.userId(), tpl.data._id, 'replied', true

      $(e.target).val("")

  'show.bs.collapse': ->
    Meteor.call 'removeFlag', Meteor.userId(), @_id, 'unread'

  ### Hide all tooltips on row collapse and focusout of assign user field. ###
  'hidden.bs.collapse': (e, tpl) ->
    tpl.$('[data-toggle="tooltip"]').tooltip('hide')
    tpl.$('input[name="assignUser"]').val('')

  'focusout input[name="assignUser"]': (e, tpl) ->
    tpl.$('[data-toggle="tooltip"]').tooltip('hide')


Template.ticketRow.rendered = ->
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()

Template.ticketRow.helpers
  changelog: ->
    Changelog.find {ticketId: this._id}, {sort: timestamp: 1}
  changeIsType: (type) ->
    @type is type
  note: ->
    if this.type is "note" then return true else return false
  unread: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'unread'})?.v
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'replied'})
  hasAttachment: ->
    TicketFlags.findOne({ticketId: this._id, k: 'attachment'})
  file: ->
    FileRegistry.findOne {_id: this.valueOf()}
  settings: ->
    {
      position: "top"
      limit: 5
      rules: [
        {
          token: '@'
          collection: Meteor.users
          field: 'username'
          template: Template.userPill
        }
        {
          token: '#'
          collection: Tags
          field: 'name'
          template: Template.tagPill
          noMatchTemplate: Template.noMatchTagPill
        }
      ]
    }
