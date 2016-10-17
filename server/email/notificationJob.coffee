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
    {ticketNumber, emailMessageIDs} = Tickets.findOne(@params.ticketId)
    html = @params.html + "<br><br><a href='#{rootUrl}/ticket/#{ticketNumber}'>View the ticket here.</a>"
    if @params.to or @params.bcc.length > 0
      messageID = makeMessageID @params.ticketId
      headers =
        'Message-ID': messageID
        'auto-submitted': 'auto-replied'
        'x-auto-response-suppress': 'OOF, AutoReply'
      if emailMessageIDs?
        headers['References'] = emailMessageIDs.join(' ')
      Tickets.update @params.ticketId,
        $push:
          emailMessageIDs: messageID
      Email.send
        from: @params.fromEmail || fromEmail
        to: @params.toEmail
        bcc: @params.bcc
        subject: @params.subject
        html: html
        headers: headers

