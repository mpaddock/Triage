@EmailIngestion = {}

# Input:
#   message - a String or Buffer representing an unparsed SMTP mail message
#
# Should return an object with properties:
#
# .subject: "RE: Ticket about something"
# .body: "This is a reply."
# .attachments: ['fileIdX', 'fileIdY']
# .ticketNumber: 1234
# .fromEmail: "some.address@mailserver.com"
# .inReplyTo: "000.111@mailserver.com"

EmailIngestion.parse = (message) ->
  subject: "RE: Ticket about something"
  body: "This is a reply."
  attachments: ['fileIdX', 'fileIdY']
  ticketNumber: 1234
  fromEmail: "some.address@mailserver.com"
  inReplyTo: "000.111@mailserver.com"


