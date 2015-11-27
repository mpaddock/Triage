Template.userDashboard.helpers
  queue: ->
    _.map Queues.find({memberIds: Meteor.userId()}).fetch(), (q) ->
      _.extend q,
        selected: if Meteor.user().defaultQueue is q.name then 'selected'

  notificationSettings: ->
    Meteor.user()?.notificationSettings
  saved: ->
    Session.get 'saved'
  user: -> Meteor.user()

Template.settingsCheckbox.helpers
  checked: ->
    if @setting then return "checked"

Template.userDashboard.events
  'keyup input[name=newEmail]': (e, tpl) ->
    if e.which is 13
      val = tpl.$('input[name=newEmail]').val()
      if validateEmail(val)
        tpl.$('input[name=newEmail]').popover('hide')
        Meteor.users.update Meteor.userId(), {$addToSet: {emails: val}}
        tpl.$('input[name=newEmail]').val('')
      else
        tpl.$('input[name=newEmail]').popover('show')
  'click button[data-action=addEmail]': (e, tpl) ->
    val = tpl.$('input[name=newEmail]').val()
    if validateEmail(val)
      tpl.$('input[name=newEmail]').popover('hide')
      Meteor.users.update Meteor.userId(), {$addToSet: {emails: val}}
      tpl.$('input[name=newEmail]').val('')
    else
      tpl.$('input[name=newEmail]').popover('show')

  'click a[data-action=removeEmail]': (e, tpl) ->
    email = $(e.target).data('email')
    Meteor.users.update Meteor.userId(), {$pull: {emails: email}}

  'shown.bs.popover': (e, tpl) ->
    Meteor.setTimeout ->
      tpl.$('input[name=newEmail]').popover('hide')
    , 5000

  'click button[data-action=submit]': (e, tpl) ->
    defaultQueue = tpl.$('select[name=defaultQueue]').val()
    notificationSettings = {}
    _.each tpl.$('input[type=checkbox]'), (i) ->
      if $(i).is(':checked')
        notificationSettings[i.name] = true
      else
        notificationSettings[i.name] = false
         
    Meteor.users.update {_id: Meteor.userId()}, {$set: {defaultQueue: defaultQueue, notificationSettings: notificationSettings}}, (err, res) ->
      if res then Session.set 'saved', true

Template.userDashboard.rendered = () ->
  this.find('#saved-message')._uihooks =
    insertElement: (node, next) ->
      $(node).hide().insertBefore(next).fadeIn(100).delay(3000).fadeOut 500, () ->
        this.remove()
        Session.set 'saved', false
