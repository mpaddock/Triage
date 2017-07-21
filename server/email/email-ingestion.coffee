EmailIngestion = {}
MailParser = Npm.require("mailparser").MailParser
Future = Npm.require('fibers/future')
fs = Npm.require 'fs'

EmailIngestion.monitorNamedPipe = (pipePath, cb) ->
  Meteor.startup ->
    if Npm.require('cluster').isMaster
      if pipePath? #Meteor.settings.email?.smtpPipe?
        # TODO: is this sound enough, or will an exception terminate the listening?
        ingestEmailFromSmtpPipe = ->
          fs = Npm.require 'fs'
          console.log 'reading from pipe... waiting for email...'
          fs.readFile pipePath, Meteor.bindEnvironment (err, data) ->
            try
              if (err)
                console.log 'error reading from fifo!'
              else
                console.log 'read data from fifo'
                message = EmailIngestion.parse(data)
                console.log 'message is:', message

                cb.call null, message
            catch e
              console.log 'Exception ingesting email: ', e
            finally
              Meteor.setTimeout ingestEmailFromSmtpPipe, 0

        ingestEmailFromSmtpPipe()


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
  start = process.hrtime()
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
      toEmails: _.pluck mailObject.to, 'address'
    }
  mailparser.write message
  mailparser.end()
  ret = mailFuture.wait()
  elapsed = process.hrtime(start)
  elapsed = elapsed[0]*1e3 + elapsed[1]*1e-6
  console.log "Parsed email in #{elapsed}ms"
  return ret
      
EmailIngestion.extractReplyFromBody = (body, toAddresses) ->
  toAddresses = '('+toAddresses?.join('|')+')'
  regex = ///
    (^________________________________\n)?^From: #Outlook/OWA response - line of underscores followed by From:
    | ^[0-9\/]+\s<#{toAddresses}>$ # Number or slash followed by to address in brackets.
    | ^[0-9]{4}-[0-9]{2}-[0-9]{2}.*<#{toAddresses}>:$  #Gmail-style response - address preceded by date.
    | ^(>\s)?On([^]*?)wrote:$ #Other gmail-style response.
    ///m
  return body.split(regex)[0].trim()

exports.EmailIngestion = EmailIngestion
@EmailIngestion = EmailIngestion

