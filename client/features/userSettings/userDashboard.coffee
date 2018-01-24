Template.userDashboard.helpers
  queue: ->
    _.map Queues.find({memberIds: Meteor.userId()}).fetch(), (q) ->
      _.extend q,
        selected: if Meteor.user().defaultQueue is q.name then 'selected'

  notificationSettings: ->
    Meteor.user()?.notificationSettings || notificationSettingDefaults

  saved: -> Template.instance().saved.get()
  user: -> Meteor.user()
  viewOptions: -> [
      { selected: 'selected', name: 'Card' }
      { selected: null, name: 'Table' }
      { selected: null, name: 'Kanban' }
  ]


Template.userDashboard.events
  'click button[data-action=submit]': (e, tpl) ->
    defaultQueue = tpl.$('select[name=defaultQueue]').val()
    notificationSettings = {}
    _.each tpl.$('input[type=checkbox]'), (i) ->
      if $(i).is(':checked')
        notificationSettings[i.name] = true
      else
        notificationSettings[i.name] = false
         
    Meteor.users.update Meteor.userId(), { $set:{
      defaultQueue: defaultQueue,
      notificationSettings: notificationSettings
    } },
      (err, res) ->
        if res then tpl.saved.set true

Template.userDashboard.rendered = () ->
  tpl = @
  tpl.find('#saved-message')._uihooks =
    insertElement: (node, next) ->
      $(node).hide().insertBefore(next).fadeIn(100).delay(3000).fadeOut 500, () ->
        @remove()
        tpl.saved.set false

Template.userDashboard.onCreated ->
  @saved = new ReactiveVar(false)

Template.settingsCheckbox.helpers
  checked: ->
    if @setting then "checked"

notificationSettingDefaults =
  submitted: true
  authorSelfNote: true
  authorOtherNote: true
  authorStatusChanged: true
  authorAttachment: true
  associatedSelfNote: true
  associatedOtherNote: true
  associatedStatusChanged: true
  associatedAttachment: true
  associatedWithTicket: true
