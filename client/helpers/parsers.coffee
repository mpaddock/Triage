#TODO: Compress these into one template that takes an argument.

Template.timeParser.helpers
  parsedTime: -> moment(@date).fromNow()

Template.timestampFormatter.helpers
  formattedTimestamp: -> moment(@date).format('lll')

Template.dateFormatter.helpers
  formattedDate: -> moment(@date).format('YYYY-MM-DD')
