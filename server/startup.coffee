Meteor.startup ->
  [
    {
      title: "Printer broken in 723 POT"
      body: "My printer has stopped working. Could someone stop by and take a look?"
      authorId: "jrsmi222"
      tags: ["Printer", "Help Desk"]
      formFields:
        dueDate: new Date()
      submissionData:
        method: "Web"
        ipAddress: "127.0.0.1"
        hostname: "localhost"
      submittedTimestamp: new Date()
      queueName: ["Help Desk"]
    },
    {
      title: "Need poster for Event"
      body: "I need a poster for my event in 3 hours."
      authorId: "sswwee020"
      formFields:
        dueDate: new Date()
      tags: ["Design", "Event"]
      submissionData:
        method: "Form"
        ipAddress: "128.163.1.1"
        hostname: "pot001.ad.uky.edu"
      submittedTimestamp: new Date("2015-02-20")
      queueName: ["Design"]
    },
    {
      title: "Academic Science Building Site"
      body: "This is a ticket for discussion and planning of the new site for the building."
      authorId: "nmad222"
      tags: ["ProjectPlanning", "AcademicScience", "WebDev"]
      formFields:
        dueDate: new Date()
      submissionData:
        method: "Web"
        ipAddress: "128.163.133.222"
        hostname: "pot931.ad.uky.edu"
      submittedTimestamp: new Date('2015-01-33')
      queueName: ["Web Dev", "Design"]
    }
  ].forEach (x) ->
    Tickets.insert x
