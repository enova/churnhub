#= require d3
#Array.prototype.inject = (init, fn) -> this.reduce(fn, init)


window.timeline_chart = do -> 
  t = {}
  t.margin = 
    top: 20
    right: 20
    bottom: 30
    left: 70
  t.get_timestamp = (commit) -> commit.timestamp
  t.get_aggregated_additions = (commit) -> commit.aggregated_additions || 0
  t.get_aggregated_deletions = (commit) -> commit.aggregated_deletions || 0
  t.width = (window.innerWidth * .9) - t.margin.left - t.margin.right
  t.height = 150 - t.margin.top - t.margin.bottom
  t.parse_date = d3.time.format("%Y-%m-%dT%XZ").parse
  t.x = d3.scale.linear().range([0, t.width])
  t.y = d3.scale.linear().range([t.height, 0])
  t.x_axis = d3.svg.axis().scale(t.x).orient("bottom")
  t.y_axis = d3.svg.axis().scale(t.y).orient("left")  
  t.sort_timestamp_asc = (a,b) -> a.timestamp-b.timestamp
  t.additions_area = d3.svg.area()
    .x (d) -> 
      t.x d.pos
    .y0(t.height)
    .y1 (d) ->
      t.y t.get_aggregated_additions(d)
    # .interpolate("basis")
  t.deletions_area = d3.svg.area()
    .x (d) -> 
      t.x d.pos
    .y0(t.height)
    .y1 (d) ->
      t.y t.get_aggregated_deletions(d) + t.get_aggregated_additions(d)
    # .interpolate("basis")
  t.summed_additions_deletions = (d) -> 
    t.get_aggregated_additions(d) + t.get_aggregated_deletions(d)
  t.svg = d3.select("#timeline")
    .append("svg")
    .attr
      class: "timeline_chart_svg"
      width: t.width + t.margin.left + t.margin.right
      height: t.height + t.margin.top + t.margin.bottom
    .append("g")
    .attr
      transform: "translate(" + t.margin.left + "," + t.margin.top + ")"
  t.render_timeline_chart = (filtered_commits) ->
    for a in [0 .. filtered_commits.length-1]
      filtered_commits[a].pos = a if filtered_commits[a]?
    t.svg.selectAll("path").remove()
    t.svg.selectAll("g").remove()
    t.x.domain [0 , filtered_commits.length]
    t.y.domain [0, d3.max(filtered_commits, t.summed_additions_deletions)]
    a = t.svg.selectAll(".area").data([filtered_commits]).enter()
      .append("g")
      .attr
        class: "area"
    a.append("path")
      .transition()
      .attr
        d: t.deletions_area
        class: "deletions"
    a.append("path")
      .transition()
      .attr
        d: t.additions_area
        class: "additions"
    a.append("g")
      .attr
        class: "x axis"
        transform: "translate(0," + t.height + ")"
      .call t.x_axis
    a.append("g")
      .attr
        class: "y axis"
      .call(t.y_axis)
  return t

settings = 
  width: 500
  height: 500
  duration: 500

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
    # clearTimeout(Repo.timer)
    # Repo.timer = setTimeout (->
    #   Repo.render_charts()
    # ), 1000
    Repo.render_timeline()
    console.log "called render charts"

    Repo.parsedFiles++
    console.log Repo.parsedFiles
    if(Repo.parsedFiles == Repo.num_commits)
      console.log("asdf")
      Repo.render_barchart()

  render_barchart: ->
    console.log("render bar")
    Repo.format_files()
    Repo.draw()
    Repo.animate()
    Repo.set_labels()

  render_timeline: ->
    timeline_chart.render_timeline_chart (c for c in Repo.commits when c.aggregated_deletions? and c.aggregated_additions? and c.timestamp?).sort(timeline_chart.sort_timestamp_asc)

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
    console.log commit.id
    if commit.files?
      Repo.add_files commit.files
      Repo.calculate_files_of commit
      Repo.timestamp_to_d3 commit
      
    else
      console.log "Shit got sent"

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
    commit.timestamp = d3.time.format("%Y-%m-%dT%XZ").parse(commit.timestamp)
  calculate_files_of: (commit) ->
    commit.aggregated_additions = d3.sum(commit.files, (file)-> file[1])
    commit.aggregated_deletions = d3.sum(commit.files, (file)-> file[2])

  add_files: (files) ->
    for file in files
      name = file[0]
      Repo.files[name]   ||= [0, 0]
      Repo.files[name][0] += file[1]
      Repo.files[name][1] += file[2]

  format_files: ->
    Repo.formated_files   = ([name, f[0], f[1], f[0]+f[1]] for name, f of Repo.files)
    
  sort_files: ->
    Repo.formated_files.sort (a,b) -> (b[3] - a[3])
    Repo.prepared_files = Repo.formated_files
    
  draw: ->

    Repo.chart.attr
      height: Repo.formated_files.length*21
    textscale   = d3.scale.linear().domain([0, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, 100])
    # d3.max(d3.selectAll)
    changes = Repo.chart.selectAll("rect").data(Repo.formated_files).enter().append("g").attr("class", "changes")
      .append("svg:title")
      .text( (a) -> a[0])

    additions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'additions'
        y:     (f, i) -> i * 21
        width: 0
        height: 20

    deletions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'deletions'
        x:0
        y:     (f, i) -> i * 21
        height: 20
        width: 0

    bar_labels = Repo.chart.selectAll("g").data(Repo.formated_files).append("text")
      .text((f, i) -> f[3]).attr
        class: "bar-label"
        x: 5
        y: (f, i) -> i * 21 + 17
        style: (f, i) -> "fill: " + (if f[3] is 0 then "#a1f" else "#fff")
       
      
  set_labels: ->  

    labels = Repo.label_chart.selectAll("div").data(Repo.prepared_files)
      .text( (a) -> a[0])
    labels.enter()
      .append("div")
      .text( (a) -> a[0])
      .attr
        y:     (f, i) -> (i) * 21 + 15
        class: "file-names"
    labels.exit().remove()

  animate: ->
    scale   = d3.scale.log().base(2).domain([0.1, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width])
    Repo.chart.selectAll("rect.deletions")
      .transition()
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration)+500 )
      .attr
        x: (f) -> scale(f[3])*f[1]/f[3]
        width: (f, i) -> scale(f[3])*f[2]/f[3]
      
    Repo.chart.selectAll("rect.additions")
      .transition()
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration)+500)
      .attr
        width: (f, i) -> scale(f[3])*f[1]/f[3]

    
    Repo.sort_files()

    Repo.move_to_new_position() 

  move_to_new_position: ->
    Repo.chart.selectAll("rect.deletions")
      .transition()
      .delay((d, i) -> (settings.duration + 1000))
      .attr
        y: (f, i) -> Repo.prepared_files.indexOf(Repo.chart.selectAll("rect.deletions")[0][i].__data__) * 21

    Repo.chart.selectAll("rect.additions")
      .transition()
      .delay((d, i) -> (settings.duration + 1000))
      .attr
        y: (f, i) -> Repo.prepared_files.indexOf(Repo.chart.selectAll("rect.deletions")[0][i].__data__) * 21

    Repo.chart.selectAll("text.bar-label")
      .transition()
      .delay((d, i) -> (settings.duration + 1000))
      .attr
        y: (f, i) -> Repo.prepared_files.indexOf(Repo.chart.selectAll("rect.deletions")[0][i].__data__) * 21 + 17

  filter: (text) ->
    Repo.prepared_files = []
    for i in [0...Repo.formated_files.length] by 1
      if(Repo.formated_files[i][0].indexOf(text) != -1)
        Repo.prepared_files.push(Repo.formated_files[i])
    console.log(Repo.prepared_files)
    Repo.move_to_new_position()
    Repo.set_labels()

$.getJSON Repo.url, Repo.init
window.t = timeline_chart

f = $('#filter')
filter = () -> 
  a = f.val()
  window.Repo.filter(a)
  window.Repo.move_to_new_position()

f.on("input",filter)
