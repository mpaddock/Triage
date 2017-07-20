{expect} = require 'chai'
{EmailIngestion} = require './email-ingestion.coffee'

fs = Npm.require('fs')

emaildir = process.env.PWD+'/server/email/test-data/'

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
  },
  {
    file: 'uky_forwarded_to_gmail2.mail'
    expected: 'test'
  },
  {
    file: 'iphone.mail'
    expected: 'How soon can you ?'
  }
]

describe 'Email ingestion', ->
  it 'ingest reply parsing', ->
    _.each testFiles, (t) ->
      parsed = EmailIngestion.parse fs.readFileSync("#{emaildir}/#{t.file}")
      check parsed.subject, String
      check parsed.body, String
      check parsed.attachments, Array
      check parsed.headers, Object
      check parsed.fromEmail, String #SimpleSchema.RegEx.Email
      check parsed.toEmails, [String]

      expect(JSON.stringify(EmailIngestion.extractReplyFromBody(parsed.body, parsed.toEmails))).to.equal JSON.stringify(t.expected)

  it 'removes quoted-text from email replies', ->
    replies = [
      {
        message: "Here is my message.",
        quoted: """
          On Wed, Jul 15, 2015 at 1:21 PM, <somebody@triage.app> wrote:
          > This text is quoted.
          > And this is too.
        """
      },
      {
        message: "Here is another message.",
        quoted: """
          ________________________________
          From: somebody@triage.app [somebody@triage.app]
          Sent: Monday, November 18, 2015 4:00 PM
          To: triagebot@triage.app
          Subject: Something

          Blah blah blah.  This counts as quoted text.
        """
      },
      {
        message: """
          See interleaved replies below.
          On Wed, Jul 15, 2015 at 1:21 PM, <somebody@triage.app> wrote:
          > Something.
          And I think that's great!
          > Something else.
          That is also fine.  Anyway, better keep the context.
        """,
        quoted: ""
      }
    ]

    _.each replies, (r) ->
      expect(r.message).to.equal EmailIngestion.extractReplyFromBody("#{r.message}\n#{r.quoted}", ["somebody@triage.app"])

