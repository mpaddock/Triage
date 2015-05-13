Template.noteInput.helpers
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


Template.noteInput.events
  ### Uploading files. ###
  'click a[data-action=uploadFile]': (e, tpl) ->
    Media.pickLocalFile (fileId) ->
      console.log "Uploaded a file, got _id: ", fileId
      Tickets.update tpl.data.ticket, {$addToSet: {attachmentIds: fileId}}
      Meteor.call 'setFlag', Meteor.userId(), tpl.data.ticket, 'attachment', true
      Changelog.insert
        ticketId: tpl.data.ticket
        timestamp: new Date()
        authorId: Meteor.userId()
        authorName: Meteor.user().username
        type: "attachment"
        message: "added file " + FileRegistry.findOne({_id: fileId})?.filename
        otherId: fileId

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
    Changelog.insert
      ticketId: tpl.data.ticket
      timestamp: new Date()
      authorId: Meteor.userId()
      authorName: Meteor.user().username
      type: "note"
      message: e.target.value

    Meteor.call 'setFlag', Meteor.userId(), tpl.data.ticket, 'replied', true
    $(e.target).val("")
