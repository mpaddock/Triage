rootUrl = Meteor.absoluteUrl()
if rootUrl[rootUrl.length-1] == '/'
  rootUrl = rootUrl.substr(0, rootUrl.length-1)
fromEmail = Meteor.settings.email?.fromEmail || "triagebot@as.uky.edu"
fromDomain = fromEmail.split('@').pop()

makeMessageID = (ticketId) ->
  '<'+Date.now()+'.'+ticketId+'@'+fromDomain+'>'

class @NotificationJob extends Job
  handleJob: ->
    ticketNumber = Tickets.findOne(@params.ticketId).ticketNumber
    html = @params.html + "<br><br><a href='#{rootUrl}/ticket/#{ticketNumber}'>View the ticket here.</a>"
    Email.send
      from: @params.fromEmail || fromEmail
      to: @params.toEmail
      bcc: @params.bcc
      subject: @params.subject
      html: html
      headers:
        'Message-ID': makeMessageID @params.ticketId

