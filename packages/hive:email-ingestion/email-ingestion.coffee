EmailIngestion = {}
MailParser = Npm.require("mailparser").MailParser
Future = Npm.require('fibers/future')

# Input:
#   message - a String or Buffer representing an unparsed SMTP mail message
#
# Should return an object with properties:
#
# .subject: "RE: Ticket about something"
# .body: "This is a reply."
# .attachments: ['fileIdX', 'fileIdY']
# .fromEmail: "some.address@mailserver.com"
# .headers: { 'header1': 'value1', 'header2': 'value2'}

EmailIngestion.parse = (message) ->
  mailFuture = new Future()
  mailparser = new MailParser({
    streamAttachments: true
  })

  mailparser.on 'end', (mailObject) ->
    mailFuture.return {
      subject: mailObject.subject
      attachments: []
      body: mailObject.text
      headers: mailObject.headers
      fromEmail: mailObject.from?[0].address
    }
  mailparser.write message
  mailparser.end()
  return mailFuture.wait()
      
EmailIngestion.extractReplyFromBody = (body) ->
  console.log body
