# Adds additional text fields to a ticket for MongoDB text indexing. These fields are
# usually drawn from Changelog entries, but could be from any entity that references a ticket
# (e.g. OCR from attachments and attachment filenames).
class @TextAggregateJob extends Job
  handleJob: ->
    Tickets.direct.update @params.ticketId, { $addToSet: { additionalText: { $each: @params.text } } }
