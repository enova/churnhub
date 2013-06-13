#= require d3
#= require underscore

Number.prototype.clip = (min, max) -> Math.min(max, Math.max(min, this))

window.timeline_chart = do ->
  t = {}
  t.recalculate = ->
    t.width = window.innerWidth
    t.rx = d3.scale.linear().domain([0, t.width])
    t.x = d3.scale.linear().range([0, t.width])
  t.get_timestamp = (commit) -> commit.timestamp
  t.get_aggregated_additions = (commit) -> commit.aggregated_additions or 0
  t.get_aggregated_deletions = (commit) -> commit.aggregated_deletions or 0
  t.width  = $("#timeline").width()
  t.height = $("#timeline").height()
  t.parse_date = d3.time.format("%Y-%m-%dT%XZ").parse
  t.rx = d3.scale.linear().domain([0, t.width])
  t.x = d3.scale.linear().range([0, t.width])
  t.y = d3.scale.linear().range([t.height, 0])
  t.stack = d3.layout.stack().offset("zero")
  t.layer = (commits) -> t.stack [({x: commit.pos, y: t.get_aggregated_additions(commit), y0: 0} for commit in commits), ({x: commit.pos, y: t.get_aggregated_deletions(commit), y0: t.get_aggregated_additions} for commit in commits)]
  t.area = d3.svg.area().x((d) ->
    t.x d.x
  ).y0((d) ->
    t.y d.y0
  ).y1((d) ->
    t.y d.y + d.y0
  )
  t.get_timestamp_range = (min_screen_x, max_screen_x) -> 
    a = Math.floor(t.rx min_screen_x)
    b = Math.ceil(t.rx max_screen_x)
    console.log "get_timestamp_range", a,b,[t.filtered_commits[a].timestamp, t.filtered_commits[b].timestamp]
    [t.filtered_commits[a].timestamp, t.filtered_commits[b].timestamp]
  # t.x_axis = d3.svg.axis().scale(t.x).orient("bottom")
  # t.y_axis = d3.svg.axis().scale(t.y).orient("left")
  t.sort_timestamp_asc = (a,b) -> a.timestamp-b.timestamp
  t.summed_additions_deletions = (d) ->
    t.get_aggregated_additions(d) + t.get_aggregated_deletions(d)
  t.svg = d3.select("#timeline")
    .append("svg")
    .attr
      class: "timeline_chart_svg"
      width: t.width
      height: t.height
  t.render_timeline_chart = (filtered_commits) ->
    for i in [0 .. filtered_commits.length-1]
      filtered_commits[i].pos = i if filtered_commits[i]?
    t.filtered_commits = filtered_commits
    t.svg.selectAll("path").remove()
    t.svg.selectAll("g").remove()
    t.x.domain [0 , filtered_commits.length]
    t.y.domain [0, d3.max(filtered_commits, t.summed_additions_deletions)]
    t.rx.range [0 , filtered_commits.length-1]
    a = t.svg.selectAll(".area").data(t.layer filtered_commits)

    a.enter()
      .append("g")
      .attr
        class: "area"
      .append("path")
      .transition()
      .attr
        d: t.area
        class: (d,i) -> if i is 0 then "additions" else "deletions"

    c = t.svg.selectAll(".point").data(filtered_commits)
    c.enter()
      .append("g")
      .attr("class", "point")
      .append("circle")
      .attr
        class: "deletions"
        r: 5
        cx: (d) ->
          t.x d.pos
        cy: (d) ->
          t.y t.get_aggregated_deletions(d) + t.get_aggregated_additions(d)
      .append("title")
      .text (d) -> d.timestamp
    c.exit().remove()

    # a.append("g")
    #   .attr
    #     class: "y axis"
    #   .call(t.y_axis)
  return t

do ->

  ls         = $('.left.slider')
  rs         = $('.right.slider')
  $highlight = $("#highlight")
  rs_down    = ls_down = false
  width      = $("#timeline").width()

  moved = (e) ->
    x = e.pageX - 10
    if ls_down
      x = x.clip(0, rs.offset().left - 23)
      $highlight.css left: x + 21
      ls.css         left: x
    if rs_down
      x = x.clip(ls.offset().left + 23, width - 21)
      $highlight.css right: width - x
      rs.css          left: x

  ls.on 'mousedown', -> ls_down = true
  rs.on 'mousedown', -> rs_down = true

  $(document).on('mousemove', moved).on 'mouseup mouseenter', -> rs_down = ls_down = false

settings =
  width: 500
  height: 500
  duration: 500
  lineheight: 23

window.Repo =
  chart: d3.select("#graph_chart").append("svg").attr
    class: 'chart'
    width: settings.width
    height: settings.height
  label_chart: d3.select("#label_chart").append("div").attr
    class: 'label_chart'
    width: 100
    height: settings.height
  commits: []
  url:     window.location.pathname + ".json"
  files:   {}
  formated_files: []

  parse_commit: (commit)->
    Repo.add_files commit.files
    Repo.calculate_files_of commit
    Repo.timestamp_to_d3 commit
    Repo.commits = Repo.commits.concat(commit)
    Repo.render_timeline()

    Repo.parsedFiles++
    console.log Repo.parsedFiles
    if(Repo.parsedFiles == Repo.num_commits)
      Repo.render_barchart()

  render_barchart: ->
    console.log("render bar")
    Repo.format_files()
    Repo.draw()
    Repo.animate()
    Repo.set_labels()

  render_timeline: ->
    timeline_chart.render_timeline_chart Repo.commits.sort(timeline_chart.sort_timestamp_asc)

  init: (commits) ->
    Repo.num_commits = commits.length
    Repo.parsedFiles = 0
    for commit in commits
      if commit.files?
        Repo.parse_commit(commit)
      else
        $.getJSON window.location.origin + "/commits/#{commit.id}.json", Repo.parse_commit
    Repo.render_timeline() if Object.keys(Repo.commits).length > 0

    timeline_chart.render_timeline_chart Repo.commits
    Repo.add_files commit.files
    Repo.calculate_files_of commit
    Repo.timestamp_to_d3 commit


    Repo.parsed_commits++
    console.log("finished: " + Repo.parsed_commits)

    if(Repo.parsed_commits == Repo.commits.length)
      Repo.render_charts()
  render_charts: ->
    Repo.format_files()
    Repo.draw()
    Repo.animate()
    Repo.set_labels()


  add_commits: (commits) ->
    Repo.parsed_commits = 0
    for commit in Repo.commits
      if commit.files? and commit.files.length > 0
        console.log("already had files!!!")
        Repo.parse_commit(commit)
      else
        $.getJSON window.location.origin + '/commits/' + commit.id + ".json", Repo.parse_commit

    Repo.render_timeline() if Object.keys(Repo.commits).length > 0
    console.log("finished parsing")


  timestamp_to_d3: (commit) ->
    debugger if !commit? or !commit.timestamp?
    commit.timestamp = d3.time.format("%Y-%m-%dT%XZ").parse(commit.timestamp)
  calculate_files_of: (commit) ->
    commit.aggregated_additions = d3.sum(commit.files, (file)-> file[1])
    commit.aggregated_deletions = d3.sum(commit.files, (file)-> file[2])

  add_files: (files) ->
    for file in files
      name = file[0]
      Repo.files[name]   or= [0, 0]
      Repo.files[name][0] += file[1]
      Repo.files[name][1] += file[2]

  format_files: ->
    Repo.formated_files   = ([name, f[0], f[1], f[0]+f[1]] for name, f of Repo.files)

  sort_files: ->
    Repo.formated_files.sort (a,b) -> (b[3] - a[3])
    Repo.prepared_files = Repo.formated_files

  draw: ->
    Repo.chart.attr
      height: Repo.formated_files.length * 23
    textscale   = d3.scale.linear().domain([0, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, 100])

    Repo.sort_files()
    changes = Repo.chart.selectAll("rect").data(Repo.formated_files).enter().append("g").attr("class", "changes")
      .append("svg:title")
      .text( (a) -> a[0])

    additions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'additions'
        y:     (f, i) -> i * settings.lineheight
        width: 0
        height: settings.lineheight - 3

    deletions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'deletions'
        x:0
        y:     (f, i) -> i * settings.lineheight
        height: 20
        width: 0

    bar_labels = Repo.chart.selectAll("g").data(Repo.formated_files).append("text")
      .text((f, i) -> f[3]).attr
        class: "bar-label"
        x: 5
        y: (f, i) -> i * settings.lineheight + 17
        style: (f, i) -> "fill: " + (if f[3] is 0 then "#555" else "#fff")


  set_labels: ->
    labels = Repo.label_chart.selectAll("div").data(Repo.prepared_files)
      .text( (a) -> a[0])
    labels.enter()
      .append("div")
      .text( (a) -> a[0])
      .attr
        y:     (f, i) -> (i) * settings.lineheight + 15
        class: "file-names"
    labels.exit().remove()

  animate: ->
    scale   = d3.scale.log().base(10).domain([0.1, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width])
    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration) )
      .attr
        x: (f) -> if f[3] is 0 then 0 else scale(f[3])*f[1]/f[3]
        width: (f, i) -> if f[3] is 0 then 0 else scale(f[3])*f[2]/f[3]

    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration))
      .attr
        width: (f, i) -> if f[3] is 0 then 0 else scale(f[3])*f[1]/f[3]

  #please leave this for now! I will be using this for scalling with the time line --Thomas
  animate2: ->
    scale   = d3.scale.log().base(10).domain([0.1, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width])
    Repo.chart.selectAll("rect").data(Repo.formated_files)
    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration) )
      .attr
        x: (f) -> if f[3] is 0 then 0 else scale(f[3])*f[1]/f[3]
        width: (f, i) -> if f[3] is 0 then 0 else scale(f[3])*f[2]/f[3]

    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration))
      .attr
        width: (f, i) -> if f[3] is 0 then 0 else scale(f[3])*f[1]/f[3]


    # Repo.sort_files()
    # Repo.timer = setTimeout (->
    #   Repo.move_to_new_position()
    # ), settings.duration*2

  find_index_of: (name, files_array) ->
    for i in [0...files_array.length] by 1
      if(name is files_array[i][0])
        return i
    return -1

  move_to_new_position: ->
    #Repo.prepared_files.indexOf(Repo.chart.selectAll("rect.deletions")[0][i].__data__) * 23

    Repo.chart.selectAll("rect.deletions")
      .transition()
      .attr
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files)* settings.lineheight

    Repo.chart.selectAll("rect.additions")
      .transition()
      .attr
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files)* settings.lineheight

    Repo.chart.selectAll("text.bar-label")
      .transition()
      .attr
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files)* settings.lineheight + 17

  filter: (text) ->
    Repo.prepared_files = []
    for i in [0...Repo.formated_files.length] by 1
      if(Repo.formated_files[i][0].indexOf(text) != -1)
        Repo.prepared_files.push(Repo.formated_files[i])
    console.log(Repo.prepared_files)
    Repo.move_to_new_position()
    Repo.set_labels()

  display_with_filtered_commits: (filtered_commits) ->
    temp_files_accumilator = []
    for commit in filtered_commits
      for file in commit.files
        name = file[0]
        Repo.files[name]   or= [0, 0]
        Repo.files[name][0] += file[1]
        Repo.files[name][1] += file[2]
    temp_files = ([name, f[0], f[1], f[0]+f[1]] for name, f of temp_files_accumilator)
    Repo.prepared_files = temp_files.sort (a,b) -> (b[3] - a[3])
    move_to_new_position()

    correct_object: (i) -> return Repo.prepared_files[Repo.prepared_files[Repo.find_index_of(f[0], Repo.prepared_files)]]
    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.prepared_files.length * settings.duration) )
      .attr
        x: (f, i) -> if correct_object(i)[3] is 0 then 0 else scale(correct_object(i)[3])*correct_object(i)[1]/correct_object(i)[3]
        width: (f, i) -> if correct_object(i)[3] is 0 then 0 else scale(correct_object(i)[3])*correct_object(i)[2]/correct_object(i)[3]

    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration))
      .attr
        width: (f, i) -> if correct_object(i)[3] is 0 then 0 else scale(correct_object(i)[3])*correct_object(i)[1]/correct_object(i)[3]

    Repo.animate2()

$.getJSON Repo.url, Repo.init
window.t = timeline_chart
$(window).resize -> 
  timeline_chart.recalculate()
  Repo.render_timeline()
f = $('#filter')
filter = () ->
  a = f.val()
  window.Repo.filter(a)
  window.Repo.move_to_new_position()

f.on("input",filter)
