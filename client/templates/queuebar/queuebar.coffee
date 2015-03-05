Template.queuebar.helpers
  queue: -> Queues.find {$or: [{members: Meteor.user().username}, {admins: Meteor.user().username}]}
  active: ->
    if this.name is Session.get("queueName")
      return "active"
    else
      return null


Template.newQueueModal.events
  'click button[data-action=checkAdmins]': (e, tmpl) ->
    username = tmpl.find('input[name=queueAdmins]').value
    if Session.get("queueAdmins")?.indexOf(username) > -1 or not username
      tmpl.$('input[name=queueAdmins]').val("")
    else
      Meteor.call "checkUsername", username, (err, res) ->
        if res
          admins = Session.get("queueAdmins") || []
          #array.push() is shitty and non-functional and i hate it
          admins.push(username)
          Session.set "queueAdmins", admins
          tmpl.$('input[name=queueAdmins]').val("")
        else
          console.log "Err in username checking: " + err


  'click button[data-action=checkMembers]': (e, tmpl) ->
    username = tmpl.find('input[name=queueMembers]').value
    if Session.get("queueMembers")?.indexOf(username) > -1 or not username
      tmpl.$('input[name=queueMembers]').val("")
    else
      Meteor.call "checkUsername", username, (err, res) ->
        if res
          members = Session.get("queueMembers") || []
          members.push(username)
          Session.set "queueMembers", members
          tmpl.$('input[name=queueMembers]').val("")
        else
          console.log "Err in username checking: " + err
   
  'click a[data-action=removeAdmin]': (e, tmpl) ->
    username = $(e.target).closest("a").data("user")
    admins = Session.get "queueAdmins"
    admins.splice admins.indexOf(username), 1
    Session.set "queueAdmins", admins

  'click a[data-action=removeMember]': (e, tmpl) ->
    username = $(e.target).closest("a").data("user")
    members = Session.get "queueMembers"
    members.splice members.indexOf(username), 1
    Session.set "queueMembers", members

  'click button[data-action=submit]': (e, tmpl) ->
    #TODO: Validation.
    name = tmpl.find('input[name=queueName]').value
    if name and Session.get("queueAdmins") and Session.get("queueMembers")
      Queues.insert
        name: name
        admins: Session.get("queueAdmins")
        members: Session.get("queueMembers")
      Session.set "queueAdmins", null
      Session.set "queueMembers", null
      tmpl.$('input[name=queueName]').val("")
      tmpl.$('input[name=queueAdmins]').val("")
      tmpl.$('input[name=queueMembers]').val("")
      tmpl.$('#newQueueModal').modal('hide')

Template.newQueueModal.helpers
  queueAdmins: -> Session.get "queueAdmins"
  queueMembers: -> Session.get "queueMembers"
