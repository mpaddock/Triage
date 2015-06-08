Template.ticketChangelogItem.helpers
  changeIsType: (type) ->
    @type is type
  note: ->
    if this.type is "note" then return true else return false
  file: ->
    FileRegistry.findOne {_id: this.valueOf()}

Template.ticketInfoTable.helpers
  admin: ->
    _.contains Queues.findOne({name: @queueName})?.memberIds, Meteor.userId()
  file: ->
    FileRegistry.findOne {_id: this.valueOf()}
  settings: ->
    {
      position: "top"
      limit: 5
      rules: [
        collection: Meteor.users
        field: 'username'
        template: Template.userPill
        noMatchTemplate: Template.noMatchUserPill
      ]
    }
 
Template.ticketInfoTable.events
  'click a[data-action=addTag]': (e, tpl) ->
    #Manual DOM manipulation since we don't want to update every ticket row at once.
    $(e.target).hide()
    tpl.$('input[name=addTag]').show()
  'keyup input[name=addTag]': (e, tpl) ->
    if e.which is 13
      val = $(e.target).val()?.split(' ')
      Tickets.update tpl.data._id, {$addToSet: {tags: $each: val}}
      $(e.target).hide()
      $(e.target).val('')
      tpl.$('a[data-action=addTag]').show()
  'keyup input[name=assignUser]': (e, tpl) ->
    if e.which is 13
      id = Meteor.call 'checkUsername', $(e.target).val(), (err, res) ->
        if res
          tpl.$('[data-toggle="tooltip"]').tooltip('hide')
          Tickets.update tpl.data._id, {$addToSet: {associatedUserIds: res}}
          $(e.target).val('')
        else
          tpl.$('[data-toggle="tooltip"]').tooltip('show')

Template.ticketNoteInput.helpers
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


Template.ticketNoteInput.events
  ### Uploading files. ###
  'click a[data-action=uploadFile]': (e, tpl) ->
    Media.pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Tickets.update tpl.data.ticket, {$addToSet: {attachmentIds: fileId}}
      Meteor.call 'setFlag', Meteor.userId(), tpl.data.ticket, 'attachment', true

  ### Adding notes to tickets. ###
  'keyup input[name=newNoteAdmin]': (e, tpl) ->
    if (e.which is 13) and (e.target.value isnt "")
      body = e.target.value
      hashtags = getTags body
      users = getUserIds body
      status = getStatuses body
      if status?.length > 0
        Tickets.update tpl.data.ticket, {$set: {status: status[0]}} #If multiple results, just use the first.

      if users?.length > 0
        Tickets.update tpl.data.ticket, {$addToSet: {associatedUserIds: $each: users}}

      if hashtags?.length > 0
        Tickets.update tpl.data.ticket, {$addToSet: {tags: $each: hashtags}}

      Changelog.insert
        ticketId: tpl.data.ticket
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "note"
        message: e.target.value

      Meteor.call 'setFlag', Meteor.userId(), tpl.data.ticket, 'replied', true

      $(e.target).val("")

  'keyup input[name=newNote]': (e, tpl) ->
    if (e.which is 13) and (e.target.value isnt "")
      Changelog.insert
        ticketId: tpl.data.ticket
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "note"
        message: e.target.value

      Meteor.call 'setFlag', Meteor.userId(), tpl.data.ticket, 'replied', true
      $(e.target).val("")
    
Template.ticketTag.events
  'click a[data-action=removeTag]': (e, tpl) ->
    e.preventDefault()
    ticketId = Template.parentData(1)._id
    Tickets.update {_id: ticketId}, {$pull: {tags: this.valueOf()}}
  
  'click a[data-action=addTagFilter]': (e, tpl) ->
    e.preventDefault()
    value = this.valueOf()
    filter = Iron.query.get('tag')?.split(',') || []
    unless filter.indexOf(value) > -1
      filter.push(value)
    Iron.query.set 'tag', filter.join()

Template.ticketHeading.helpers
  author: ->
    Meteor.users.findOne {_id: @authorId}
