EmailIngestion = {}
MailParser = Npm.require("mailparser").MailParser
Future = Npm.require('fibers/future')
fs = Npm.require 'fs'

# Input:
#   message - a String or Buffer representing an unparsed SMTP mail message
#
# Should return an object with properties:
#
# .subject: "RE: Ticket about something"
# .body: "This is a reply."
# .attachments: ['fileIdX', 'fileIdY']
# .fromEmail: "some.address@mailserver.com"
# .toEmail: "some.other.address@mailserver.com"
# .headers: { 'header1': 'value1', 'header2': 'value2'}

EmailIngestion.parse = (message) ->
  mailFuture = new Future()
  mailparser = new MailParser()

  mailparser.on 'end', Meteor.bindEnvironment (mailObject) ->
    attachments = []
    if mailObject.attachments

      fd = FileRegistry.getFileRoot()
      if not fs.existsSync fd
        fs.mkdirSync fd

      _.each mailObject.attachments, (a) ->
        fn = Date.now() + '-' + a.fileName
        fs.writeFileSync fd + fn, a.content
        id = FileRegistry.insert
          filename: a.fileName
          filenameOnDisk: fn
          size: a.length
          timestamp: new Date()
        attachments.push(id)
        FileRegistry.scheduleJobsForFile fn

    mailFuture.return {
      subject: mailObject.subject
      attachments: attachments
      body: mailObject.text
      headers: mailObject.headers
      fromEmail: mailObject.from?[0].address
      toEmail: mailObject.to?[0].address
    }
  mailparser.write message
  mailparser.end()
  return mailFuture.wait()
      
EmailIngestion.extractReplyFromBody = (body, toAddress) ->
  regex = ///
    (^________________________________\n)?^From: #Outlook/OWA response - line of underscores followed by From:
    | ^[0-9\/]+\s<#{toAddress}>$ # Number or slash followed by to address in brackets.
    | ^[0-9]{4}-[0-9]{2}-[0-9]{2}.*<#{toAddress}>:$  #Gmail-style response - address preceded by date.
    | ^On.+?,\s<#{toAddress}>wrote: #Other gmail-style response.
    ///m
  return body.split(regex)[0].trim()
