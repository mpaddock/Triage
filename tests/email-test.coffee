testFiles = [
  {
    file: 'uky_forwarded_to_gmail.mail'
    expected: "I use gmail--my uk email is forwarded to a gmail account.\n\nWaggle User"
    storyid: 719679
  },
  {
    file: 'outlook_web_app.mail'
    expected: 'This sholud definitely become a comment.'
    storyid: 720971
  },
  {
    file: 'base64_plaintext.mail'
    expected: 'This is a reply.'
    storyid: 720997
  }
]

Tinytest.add 'Email - ingest reply parsing', (test) ->
  _.each testFiles, (t) ->
    parsed = EmailIngestion.parse(t.file)
    check parsed.subject, String
    check parsed.body, String
    check parsed.attachments, Array
    check parsed.ticketNumber, Number
    check parsed.fromEmail, String #SimpleSchema.RegEx.Email
    check parsed.inReplyTo, String #SimpleSchema.RegEx.Email

    test.equal t.expected, EmailIngestion.parse(t.file).body

