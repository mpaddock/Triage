Template.stats.onCreated ->
  @ready = new ReactiveVar false
  tpl = @

Template.stats.helpers
  ready: ->
    Template.instance().ready.get()
  noResults: ->
    Template.instance().ready.get() and !Stats.count()
  stats: -> Stats.find()
  startDate: -> Iron.query.get('startDate')
  endDate: -> Iron.query.get('endDate')

Template.stats.events
 'changeDate .input-daterange input': (e, tpl) ->
    if e.date
      Iron.query.set tpl.$(e.target).data('filter'), moment(e.date).format('YYYY-MM-DD')
    else
      # Clear button
      Iron.query.set tpl.$(e.target).data('filter'), null

  'click button[data-action=reset]': ->
    dc.filterAll()
    dc.redrawAll()

Template.stats.onRendered ->
  @.$('.input-daterange').datepicker({
    clearBtn: true
    todayHighlight: true
    format: 'yyyy-mm-dd'
  })

  @autorun =>
    startDate = endDate = null
    if Iron.query.get('startDate')
      startDate = moment(Iron.query.get('startDate')).toDate()
      endDate = moment(Iron.query.get('endDate')).toDate()
    @subscribe 'stats',
      startDate,
      endDate,
      onReady: =>
        @ready.set true
      onStop: =>
        @ready.set false

  @autorun =>
    if @ready.get()
      stats = Stats.find().fetch()
      data = crossfilter(stats)
      all = data.groupAll()

      margins = { top: 20, left: 10, right: 10, bottom: 20 }

      queueDimension = data.dimension (d) -> d.queueName
      queueGroup = queueDimension.group()


      countsByQueue = queueDimension.group().reduceSum (d) -> d.count

      closedByUsernameDimension = data.dimension (d) -> d.closedByUsername
      closedByUsernameGroup = closedByUsernameDimension.group()

      countsByCloser = closedByUsernameDimension.group().reduceSum (d) -> d.count

      countDimension = data.dimension (d) -> d.count
      countGroup = countDimension.group()

      ###
      monthlyClosedDimension = data.dimension (d) ->
        d3.time.month(d.closedTimestamp).getMonth()
      ###

      byQueue = dc.rowChart('#tickets-by-queue')
      byQueue
        .width(800)
        .height(600)
        .margins(margins)
        .group(countsByQueue)
        .dimension(queueDimension)

        .title (d) -> d.queueName
        .elasticX(true)

      byQueue.render()

      byCloser = dc.rowChart('#tickets-by-closer')
      byCloser
        .width(800)
        .height(600)
        .margins(margins)
        .group(countsByCloser)
        .dimension(closedByUsernameDimension)
        .title (d) -> d.closedByUsername
        .elasticX(true)

      byCloser.render()
      byCloser.turnOnControls(true)

      dataTable = dc.dataTable('#data-table')
        .dimension(queueDimension)
        .group (d) ->
          d.queueName
        .size(20)
        .columns([
          'queueName'
          'closedByUsername'
          {
            label: "Average Closing Time",
            format: (d) ->
              secondsToString d.timeToClose
          }
          'count'
        ])

      dataTable.render()



secondsToString = (seconds) ->
  numdays = Math.floor((seconds % 31536000) / 86400)
  numhours = Math.floor(((seconds % 31536000) % 86400) / 3600)
  numminutes = Math.floor((((seconds % 31536000) % 86400) % 3600) / 60)
  numseconds = Math.floor (((seconds % 31536000) % 86400) % 3600) % 60
  return numdays + " days " + numhours + " hours " + numminutes + " minutes " + numseconds + " seconds"

