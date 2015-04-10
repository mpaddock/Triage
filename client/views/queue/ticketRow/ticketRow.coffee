Template.ticketRow.events
  ### Events for ticket status changes. ###
  'click .dropdown-menu[name=statusMenu]': (e, tmpl) ->
    #Needed to stop wacky table row expansion. We have to toggle the dropdown manually as a result in our events.
    e.stopPropagation()
  'click .dropdown-menu[name=statusMenu] a': (e, tmpl) ->
    Meteor.call 'updateStatus', Meteor.userId(), this._id, $(e.target).html()
    tmpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')

  
  'keyup input[name=customStatus]': (e, tmpl) ->
    if e.which is 13
      Meteor.call 'updateStatus', Meteor.userId(), this._id, e.target.value
      $(e.target).val("")
      tmpl.$('.dropdown-toggle[name=statusButton]').dropdown('toggle')
    
  ### Assigning users to tickets. ###
  'keyup input[name=assignUser]': (e, tmpl) ->
    if e.which is 13
      item = this
      id = Meteor.call 'checkUsername', e.target.value, (err, res) ->
        if res
          tmpl.$('[data-toggle="tooltip"]').tooltip('hide')
          Session.set "assignError", false
          Tickets.update item._id, {$addToSet: {associatedUserIds: res}}
          $(e.target).val('')
        else
          tmpl.$('[data-toggle="tooltip"]').tooltip('show')

  'click a[data-action=uploadFile]': ->
    item = this
    getMediaFunctions().pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Tickets.update item._id, {$addToSet: {attachmentIds: fileId}}
      Meteor.call 'setFlag', Meteor.userId(), item._id, 'attachment', true
      Changelog.insert
        ticketId: item._id
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "attachment"
        message: "added file " + FileRegistry.findOne({_id: fileId}).filename

  ### Adding notes to tickets. ###
  'keyup input[name=newNote]': (e, tmpl) ->
    if (e.which is 13) and (e.target.value isnt "")
      body = e.target.value
      hashtags = getTags body
      users = getUsers body

      if users?.length > 0
        Tickets.update this._id, {$addToSet: {associatedUserIds: $each: users}}

      if hashtags?.length > 0
        Tickets.update this._id, {$addToSet: {tags: $each: hashtags}}

      Changelog.insert
        ticketId: this._id
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "note"
        message: e.target.value

      Meteor.call 'setFlag', Meteor.userId(), this._id, 'replied', true

      $(e.target).val("")
  # Hide all tooltips on row collapse and focusout of assign user field. 
  'hidden.bs.collapse': (e, tmpl) ->
    tmpl.$('[data-toggle="tooltip"]').tooltip('hide')
    tmpl.$('input[name="assignUser"]').val('')

  'focusout input[name="assignUser"]': (e, tmpl) ->
    tmpl.$('[data-toggle="tooltip"]').tooltip('hide')


Template.ticketRow.rendered = ->
  $('form[name=ticketForm]').submit (e) -> e.preventDefault()
  $('[data-toggle=popover]').popover()

Template.ticketRow.helpers
  changelog: ->
    Changelog.find {ticketId: this._id}, {sort: timestamp: 1}
  note: ->
    if this.type is "note" then return true else return false
  repliedTo: ->
    TicketFlags.findOne({userId: Meteor.userId(), ticketId: this._id, k: 'replied'})
  hasAttachment: ->
    TicketFlags.findOne({ticketId: this._id, k: 'attachment'})
  allFields: ->
    Session.get "allFields"
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
          field: "username"
          template: Template.userPill
        }
        {
          token: '#'
          #collection: Tags
          field: "name"
        }
      ]
    }
