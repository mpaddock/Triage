Template.userDashboard.helpers
  queue: ->
    _.map Queues.find({memberIds: Meteor.userId()}).fetch(), (q) ->
      _.extend q,
        selected: if Meteor.user().defaultQueue is q.name then 'selected'

  notificationSettings: ->
    Meteor.user()?.notificationSettings

  saved: -> Template.instance().saved.get()
  user: -> Meteor.user()
  name: -> Meteor.users.findOne(@valueOf())?.displayName

Template.userDashboard.events
  'autocompleteselect input[name=newSharedWithUser]': (e, tpl) ->
    tpl.$('button[data-action=addSharedWithUser]').click()

  'keyup input[name=newSharedWithUser]': (e, tpl) ->
    if e.keyCode is 13
      tpl.$('button[data-action=addSharedWithUser]').click()

  'click button[data-action=addSharedWithUser]': (e, tpl) ->
    id = Meteor.users.findOne({username: tpl.$('input[name=newSharedWithUser]').val()})?._id
    if id and id isnt Meteor.userId()
      Meteor.users.update Meteor.userId(), { $addToSet: { shareTicketsWithUserIds: id } }
      tpl.$('input[name=newSharedWithUser]').val('')
    else if id is Meteor.userId()
      tpl.$('input[name=newSharedWithUser]').val('')
    else
      tpl.$('input[name=newSharedWithUser]').tooltip('show')
      Meteor.setTimeout ->
        tpl.$('input[name=newSharedWithUser]').tooltip('hide')
      , 3000

  'click a[data-action=removeSharedWithUser]': (e, tpl) ->
    Meteor.users.update Meteor.userId(), { $pull: { shareTicketsWithUserIds: @valueOf() } }

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
