Meteor.startup ->
  if not Meteor.settings?
    Meteor.settings = {}

  # Set defaults for any client/server settings
  Meteor.settings.public = _.extend
      siteTitle: "Triage"
      reopenAllowedTimespan: 7*24*60*60
      pageLimitDefault: 20
      pageLimitIncrement: 20
    , Meteor.settings.public

