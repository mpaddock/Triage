Template.ticketStats.onCreated ->
  @ready = new ReactiveVar false
  @ticketStats = new ReactiveVar([])
  tpl = @
  Meteor.apply 'getTicketsForStats', [], (err, stats) ->
    tpl.ticketStats.set stats
    tpl.ready.set true

Template.ticketStats.helpers
  ready: ->
    Template.instance().ready.get()
  noResults: ->
    Template.instance().ready.get() and !Template.instance().ticketStats.get().length
  stats: -> Template.instance().ticketStats.get()

Template.ticketStats.events
 'changeDate .input-daterange input': (e, tpl) ->
    if e.date
      Iron.query.set tpl.$(e.target).data('filter'), moment(e.date).format('YYYY-MM-DD')
    else
      # Clear button
      Iron.query.set tpl.$(e.target).data('filter'), null

  'click button[data-action=reset]': ->
    dc.filterAll()
    dc.redrawAll()

Template.ticketStats.onRendered ->
  @.$('.input-daterange').datepicker({
    clearBtn: true
    todayHighlight: true
    format: 'yyyy-mm-dd'
  })

  ###
  @autorun =>
    @subscribe 'ticketStats',
      onReady: =>
        @ready.set true
      onStop: =>
        @ready.set false
  ###

  @autorun =>
    stats = @ticketStats.get() #TicketStats.find().fetch()
    if @ready.get() and stats?.length
      data = crossfilter(stats)

      all = data.groupAll()

      margins = { top: 20, left: 40, right: 10, bottom: 20 }
      dateFormat = d3.time.format('%Y-%m-%d')
      dayDim = data.dimension (d) ->
        dateFormat.parse(dateFormat(d.submittedTimestamp))
      submittedGroup = dayDim.group()
      closedPerDayDim = data.dimension (d) ->
        dateFormat.parse(dateFormat(d.closedTimestamp))
      closedGroup = closedPerDayDim.group()

      closedByUsernameDim = data.dimension (d) ->
        d.closedByUsername
      closedByUsernameGroup = closedByUsernameDim.group()
      add = (p, v) ->
        p.count++
        p.total += v.timeToClose
        p.avg = p.total / p.count
        p
      sub = (p, v) ->
        p.count--
        p.total -= v.timeToClose
        if p.count is 0 then p.avg = 0 else p.avg = p.total / p.count
        p
      initial = ->
        { count: 0, total: 0, avg: 0 }
      timeToCloseGroup = closedByUsernameDim.group().reduce(add, sub, initial)


      queueDim = data.dimension (d) -> d.queueName
      queueGroup = queueDim.group()
      departmentDim = data.dimension (d) -> d.submitterDepartment
      departmentGroup = departmentDim.group()


      # Range chart, with submitted for bars
      volumeChart = dc.barChart('#volume-chart')
        .height(100)
        .width(window.innerWidth * 2/3 - 50)
        .margins(margins)
        .dimension(dayDim)
        .group(submittedGroup)
        .centerBar(true)
        .gap(1)
        #.x(d3.time.scale().domain([new Date(2015, 6, 1), new Date()]))
        .x(d3.time.scale().domain([new Date(Date.now() - 1000*60*60*24*30), new Date(Date.now() + 1000*60*60*24)]))
        .round(d3.time.day.round)
        .alwaysUseRounding(true)
        .xUnits(d3.time.day)

      volumeChart.render()

      # Composite line chart
      lineChart = dc.compositeChart('#tickets-by-day')
      lineChart
        .width(window.innerWidth * 2/3 - 50)
        #.height(window.innerHeight - 300)
        .height(200)
        .transitionDuration(1000)
        .margins(margins)
        .dimension(dayDim)
        .mouseZoomable(false)
        .brushOn(false)
        .x(d3.time.scale().domain([new Date(Date.now() - 1000*60*60*24*30), new Date(Date.now() + 1000*60*60*24)]))
        .round(d3.time.day.round)
        .xUnits(d3.time.day)
        .elasticY(true)
        .legend(dc.legend().x(window.innerWidth - 400).y(10).itemHeight(13).gap(5))
        .renderHorizontalGridLines(true)

        .compose([
          # Make lines, set colors, empty titles for d3-tip
          dc.lineChart(lineChart).group(submittedGroup, 'Tickets Submitted').colors('red').title (d) -> ""
          dc.lineChart(lineChart).group(closedGroup, 'Tickets Closed').colors('blue').title (d) -> ""
        ])
        .rangeChart(volumeChart)

      # Render line charts
      lineChart.render()

      # Pie/donut chart for queue
      queuePieChart = dc.pieChart("#tickets-by-queue")
      queuePieChart
        .width(window.innerWidth/6 - 50)
        .height(window.innerWidth/6 - 50)
        .radius(80)
        .dimension(queueDim)
        .group(queueGroup)
        .renderLabel(true)
        #.label (d) -> d.queueName
        #.innerRadius(20)

      queueName = Iron.query.get('queueName')
      if queueName?
        console.log 'filtering queueDim to ' + queueName
        queuePieChart.filter queueName

      queuePieChart.render()

      departmentPieChart = dc.pieChart("#tickets-by-submitter-department")
      departmentPieChart
        .width(window.innerWidth/6 - 50)
        .height(window.innerWidth/6 - 50)
        .radius(89)
        .dimension(departmentDim)
        .group(departmentGroup)
        .renderLabel(true)

      departmentPieChart.render()

      closedByUserRowChart = dc.rowChart('#tickets-closed-by-user')
      closedByUserRowChart
        .width(window.innerWidth / 3 - 50)
        .height(600)
        .margins(margins)
        .dimension(closedByUsernameDim)
        .group(closedByUsernameGroup)
        .label (d) ->
          d.key + " - " + d.value
        .elasticX(true)

      closedByUserRowChart.render()
      closedByUserRowChart.turnOnControls(true)

      timeToCloseRowChart = dc.rowChart('#time-to-close-by-user')
      timeToCloseRowChart
        .width(window.innerWidth /3 - 50)
        .height(600)
        .margins(margins)
        .dimension(closedByUsernameDim)
        .group(timeToCloseGroup).valueAccessor (d) ->  d.value.avg
        .label (d) ->
          d.key + " - " + secondsToString(d.value.avg)
        .elasticX(true)
      timeToCloseRowChart.render()
      timeToCloseRowChart.turnOnControls(true)

      window.cb = closedByUserRowChart

      # Tooltips with d3-tip
      tip = d3.tip().attr('class', 'd3-tip').offset([-10, 0]).html (d) ->
        "<span style='color: #0b0'>#{d.data.value}</span> #{d.layer} on #{moment(d.data.key).format('l')}"
      d3.selectAll('.dot').call(tip)
      d3.selectAll('.dot')
        .on('mouseover', tip.show)
        .on('mouseleave', tip.hide)

 
secondsToString = (seconds) ->
  minutes = Math.floor(seconds / 60)
  if minutes < 60
    return minutes + " minutes"
  hours = Math.floor(minutes / 60)
  minutes -= 60 * hours
  if hours < 24
    return hours + " hours " + minutes + " minutes"
  days = Math.floor(hours / 24)
  hours -= 24 * days
  if days < 7
    return days + " days " + hours + " hours"
  weeks = Math.floor(days / 7)
  days -= 7 * weeks
  if weeks < 4
    return weeks + " weeks " + days + " days"
  months = Math.floor(weeks / 4)
  weeks -= 4 * months
  return months + " months " + weeks + " weeks"
