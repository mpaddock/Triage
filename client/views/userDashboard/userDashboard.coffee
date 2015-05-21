Template.userDashboard.helpers
  queue: ->
    _.map Queues.find({memberIds: Meteor.userId()}).fetch(), (q) ->
      _.extend q,
        selected: if Meteor.user().defaultQueue is q.name then 'selected'

  notificationSettings: ->
    Meteor.user()?.notificationSettings
  saved: ->
    Session.get 'saved'

Template.settingsCheckbox.helpers
  checked: ->
    if @setting then return "checked"

Template.userDashboard.events
  'click button[data-action=submit]': (e, tpl) ->
    defaultQueue = tpl.$('select[name=defaultQueue]').val()
    notificationSettings = {}
    _.map tpl.$('input[type=checkbox]'), (i) ->
      if $(i).is(':checked')
        notificationSettings[i.name] = true
      else
        notificationSettings[i.name] = false
         
    Meteor.users.update {_id: Meteor.userId()}, {$set: {defaultQueue: defaultQueue, notificationSettings: notificationSettings}}, (err, res) ->
      if res then Session.set 'saved', true

Template.userDashboard.rendered = () ->
  this.find('#savedMessage')._uihooks = {
    insertElement: (node, next) ->
      $(node).hide().insertBefore(next).fadeIn(100).delay(3000).fadeOut 500, () ->
        this.remove()
        Session.set 'saved', false
  }
