#= require d3
#Array.prototype.inject = (init, fn) -> this.reduce(fn, init)
filter = () -> 
  a = $('#filter').val()
  window.Repo.filter(a)
  window.Repo.update()

$('#filter').on("input",filter)

window.timeline_chart = do -> 
  t = {}
  t.margin = 
    top: 20
    right: 20
    bottom: 30
    left: 70
  t.get_timestamp = (commit) -> commit.timestamp
  t.get_aggregated_additions = (commit) -> commit.aggregated_additions
  t.get_aggregated_deletions = (commit) -> commit.aggregated_deletions
  t.width = 960 - t.margin.left - t.margin.right
  t.height = 500 - t.margin.top - t.margin.bottom
  t.parse_date = d3.time.format("%Y-%m-%dT%XZ").parse
  t.x = d3.time.scale().range([0, t.width])
  t.y = d3.scale.linear().range([t.height, 0])
  t.x_axis = d3.svg.axis().scale(t.x).orient("bottom")
  t.y_axis = d3.svg.axis().scale(t.y).orient("left")  
  t.sort_timestamp_asc = (a,b) -> a.timestamp-b.timestamp
  t.additions_area = d3.svg.area()
    .x (d) ->
      t.x t.get_timestamp(d)
    .y0(t.height)
    .y1 (d) ->
      t.y t.get_aggregated_additions(d)
    .interpolate("basis")
  t.deletions_area = d3.svg.area()
    .x (d) ->
      t.x t.get_timestamp(d)
    .y0(t.height)
    .y1 (d) ->
      t.y t.get_aggregated_deletions(d) + t.get_aggregated_additions(d)
    .interpolate("basis")
  t.svg = d3.select("body")
    .append("svg")
    .attr
      width: t.width + t.margin.left + t.margin.right
      height: t.height + t.margin.top + t.margin.bottom
    .append("g")
    .attr
      transform: "translate(" + t.margin.left + "," + t.margin.top + ")"
  t.render_timeline_chart = (filtered_commits) ->
    # Assume filtered commits are sorted
    t.x.domain d3.extent filtered_commits, (d) ->
      t.get_timestamp(d)
    summed_additions_deletions = (d) -> 
      t.get_aggregated_additions(d) + t.get_aggregated_deletions(d)
    t.y.domain [0, d3.max(filtered_commits, summed_additions_deletions)]
    t.svg.append("path").datum(filtered_commits)
      .attr
        class: "area"
        d: t.deletions_area
        fill: "red"
    t.svg.append("path").datum(filtered_commits)
      .attr
        class: "area"
        d: t.additions_area
        fill: "green"
    t.svg.append("g").attr
      class: "x axis"
      transform: "translate(0," + t.height + ")"
    .call t.x_axis
    t.svg.append("g").attr
      class: "y axis"
    .call(t.y_axis)
    .append("text")
    .attr
      transform: "rotate(-90)"
      y: 6
      dy: ".71em"
    .style
      "text-anchor": "end"
    .text "Ammount Changed"
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
  add_commits: (commits) ->

    Repo.commits = Repo.commits.concat(commits) # Concat commits if you get them one by one
    for commit in commits
      Repo.add_files commit.files
      Repo.calculate_files_of commit
      Repo.timestamp_to_d3 commit
    Repo.commits.sort(timeline_chart.sort_timestamp_asc)

    Repo.format_files()
    Repo.draw()
    Repo.animate()
    Repo.set_labels()

    timeline_chart.render_timeline_chart Repo.commits

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

    
  #  draw_refactor: ->  
  #    files   = ({name:name, additions:f[0], deletions:f[1], changes:f[0]+f[1]} for name, f of Repo.files)
  #    files.sort (a,b) -> b.changes - a.changes
  #    scale   = d3.scale.linear().domain([0, d3.max(files, (d)-> d.changes)]).range([0, settings.width])
  #    # textscale   = d3.scale.linear().domain([0, d3.max(files, (d)-> d.changes )]).range([0, 100])
  #    chart = Repo.chart.selectAll("g").append("g").attr("class", "mainGroup")
  #    group = Repo.chart.selectAll("rect")

  draw: ->
    scale   = d3.scale.linear().domain([0, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width])
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
    scale   = d3.scale.linear().domain([0, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width])
    #console.log(Repo.chart.selectAll("rect.deletions"))
    Repo.chart.selectAll("rect.deletions")
      .transition()
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration)+500 )
      .attr
        x: (f) -> scale(f[1])
        width: (f, i) -> scale(f[2])
      
    Repo.chart.selectAll("rect.additions")
      .transition()
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration)+500)
      .attr
        width: (f, i) -> scale(f[1])

    
    Repo.sort_files()

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

  update: ->
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

  filter: (text) ->
    Repo.prepared_files = []
    for i in [0...Repo.formated_files.length] by 1
      if(Repo.formated_files[i][0].indexOf(text) != -1)
        Repo.prepared_files.push(Repo.formated_files[i])
    console.log(Repo.prepared_files)
    Repo.update()
    Repo.set_labels()

$.getJSON Repo.url, Repo.add_commits
window.t = timeline_chart
