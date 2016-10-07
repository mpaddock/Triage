Template.navbar.helpers
  siteTitle: -> Meteor.settings.public.siteTitle

Template.navbar.events
  'click a[id=logout]': ->
    Meteor.logout()
