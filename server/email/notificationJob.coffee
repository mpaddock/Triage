rootUrl = Meteor.absoluteUrl()
if rootUrl[rootUrl.length-1] == '/'
  rootUrl = rootUrl.substr(0, rootUrl.length-1)
fromEmail = Meteor.settings.email?.fromEmail || "triagebot@as.uky.edu"
fromDomain = fromEmail.split('@').pop()

makeMessageID = (ticketId) ->
  '<'+Date.now()+'.'+ticketId+'@'+fromDomain+'>'

# Sends notifications to users about ticket updates.
class @NotificationJob extends Job
  handleJob: ->
    sendNotification @params

sendNotification = (options) ->
  {ticketNumber, emailMessageIDs} = Tickets.findOne(options.ticketId)
  html = options.html + "<br><br><a href='#{rootUrl}/ticket/#{ticketNumber}'>View the ticket here.</a>"
  if options.to or options.bcc.length > 0
    messageID = makeMessageID options.ticketId
    headers =
      'Message-ID': messageID
      'auto-submitted': 'auto-replied'
      'x-auto-response-suppress': 'OOF, AutoReply'
    if emailMessageIDs?
      headers['References'] = emailMessageIDs.join(' ')
      headers['In-Reply-To'] = _.first emailMessageIDs
    Tickets.update options.ticketId,
      $push:
        emailMessageIDs: messageID
    Email.send
      from: options.fromEmail || fromEmail
      to: options.toEmail
      bcc: options.bcc
      subject: options.subject
      html: html
      headers: headers

