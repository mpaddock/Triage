fs = Npm.require('fs')

emaildir = process.env.PWD+'/packages/hive:email-ingestion/emails/'

testFiles = [
  {
    file: 'uky_forwarded_to_gmail.mail'
    expected: "I use gmail--my uk email is forwarded to a gmail account.\n\nWaggle User"
  },
  {
    file: 'outlook_web_app.mail'
    expected: "This sholud definitely become a comment."
  },
  {
    file: 'base64_plaintext.mail'
    expected: 'This is a reply.'
  },
  {
    file: 'reply_with_attachment.mail'
    expected: 'An attachment'
  },
  {
    file: 'reply_with_attachment2.mail',
    expected: "Sorry for the slow response.\n\n"+
    "I was away when you sent the first request adn then it got lost in the"+
    "\nflood.\n\n"+
    "This message has a pdf file attached."
  }
]

Tinytest.add 'Email - ingest reply parsing', (test) ->
  _.each testFiles, (t) ->
    parsed = EmailIngestion.parse fs.readFileSync("#{emaildir}/#{t.file}")
    check parsed.subject, String
    check parsed.body, String
    check parsed.attachments, Array
    check parsed.headers, Object
    check parsed.fromEmail, String #SimpleSchema.RegEx.Email
    check parsed.toEmail, String

    test.equal JSON.stringify(EmailIngestion.extractReplyFromBody(parsed.body, parsed.toEmail)), JSON.stringify(t.expected)
