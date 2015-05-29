#TODO: Compress these into one template that takes an argument.

tickDeps = new Tracker.Dependency()
Meteor.setInterval ->
  tickDeps.changed()
, 1000

Template.timeParser.helpers
  parsedTime: ->
    tickDeps.depend()
    moment(@date).fromNow()
  fullTime: -> moment(@date).format('MMMM Do YYYY, h:mm:ss a')

Template.timestampFormatter.helpers
  formattedTimestamp: -> moment(@date).format('lll')

Template.dateFormatter.helpers
  formattedDate: -> moment(@date).format('YYYY-MM-DD')
