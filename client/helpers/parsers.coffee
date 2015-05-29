tickDeps = new Tracker.Dependency

Meteor.setInterval ->
  tickDeps.changed()
, 1000

fromNowReactive = (date) ->
  tickDeps.depend()
  return moment(date).fromNow()

Template.timeParser.helpers
  parsedTime: -> fromNowReactive(@date)
  fullTime: -> moment(@date).format('MMMM Do YYYY, h:mm:ss a')

Template.timestampFormatter.helpers
  formattedTimestamp: -> moment(@date).format('lll')

Template.dateFormatter.helpers
  formattedDate: -> moment(@date).format('YYYY-MM-DD')
