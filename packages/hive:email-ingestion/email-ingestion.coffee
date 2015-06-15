EmailIngestion = {}

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
# .headers: { 'header1': 'value1', 'header2': 'value2'}

EmailIngestion.parse = (message) ->
  MailParser = Npm.require("mailparser").MailParser
  mailparser = new MailParser({
    streamAttachments: true
  })

  mailparser.on 'end', (mailObject) ->
    console.log mailObject
  mailparser.write message
  mailparser.end()
      
