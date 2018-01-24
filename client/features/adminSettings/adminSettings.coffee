Template.adminSettings.onRendered ->
    Meteor.subscribe 'allQueues'


Template.adminSettings.helpers
    appAdmins: -> Meteor.users.find { applicationRole: Constants.appAdminRole }
    queues: -> Queues.find()
    noQueues: -> Queues.find().count() is 0
    queueAdmins: (queueId) ->
        adminIds = Queues.findOne(queueId)?.adminIds
        Meteor.users.find { _id: { $in: adminIds } }


Template.adminSettings.events
    'click button': (e, tpl) ->
        button = tpl.$(e.currentTarget)
        cb = (err, res) ->
            if err
                Session.set('infoMessage', "An error occurred processing your request: #{err.reason}")
                Session.set('infoHeader', 'Error')
                Blaze.render Template.infoModal, $('body').get(0)
                $('#infoModal').modal('show')
            else if not button.data('id')
                # Clear input if successful
                tpl.$("input[name=#{action}]").val('')

        if button.data('id')
            Meteor.call button.data('action'), button.data('id'), cb
        else
            action = button.data('action')
            Meteor.call action, tpl.$("input[name=#{action}]").val(), cb

    'keyup input': (e, tpl) ->
        if e.which is 13
            name = tpl.$(e.target).attr('name')
            tpl.$("button[data-action=#{name}]").click()

