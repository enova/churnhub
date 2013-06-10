#= require d3
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

Array.prototype.inject = (init, fn) -> this.reduce(fn, init)
settings = 
  width: 420
  textWidth: 420
  height: 500
  duration: 500

window.Repo =
  canvas: d3.select("#graph_canvas").append("svg").attr
    class: 'canvas'
    width: settings.width
    height: settings.height
  label_canvas: d3.select("#label_canvas").append("div").attr
    class: 'label_canvas'
    width: 100
    height: settings.height
    # viewBox: "0 0 100 100"
  commits: []
  url:     window.location.pathname + ".json"
  files:   {}
  add_commits: (commits) ->
    Repo.commits = Repo.commits.concat(commits) # Concat commits if you get them one by one
    for commit in commits
      Repo.add_files commit.files
      Repo.calculate_files_of commit
      Repo.timestamp_to_d3 commit
    Repo.commits.sort(timeline_chart.sort_timestamp_asc)
    # Repo.draw()
    # Repo.draw_commit()
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

  draw: ->
    files   = ([name, f[0], f[1], f[0]+f[1]] for name, f of Repo.files)
    files.sort (a,b) -> b[3] - a[3]
    scale   = d3.scale.linear().domain([0, d3.max(files, (d)-> d[3] )]).range([0, settings.width])
    textscale   = d3.scale.linear().domain([0, d3.max(files, (d)-> d[3] )]).range([0, 100])
    # d3.max(d3.selectAll)
    changes = Repo.canvas.selectAll("rect").data(files).enter().append("g").attr("class", "changes")
      .append("svg:title")
      .text( (a) -> a[0])
    labels = Repo.label_canvas.selectAll("div").data(files).enter()
      .append("div")
      .text( (a) -> a[0])
      .attr
        y:     (f, i) -> (i) * 21 + 15
        class: "file-names"
    Repo.label_canvas.attr
      width: d3.max(Repo.label_canvas.selectAll("text")[0], (d) -> d.getBBox().width)
    additions = Repo.canvas.selectAll("g").data(files).insert("rect")
      .attr
        class: 'additions'
        y:     (f, i) -> i * 21
        width: 0
        height: 20
      .transition()
      .delay((d, i) -> (i / files.length * settings.duration)+500 )
      .attr
        width: (f, i) -> scale(f[1])
    deletions = Repo.canvas.selectAll("g").data(files).insert("rect")
      .attr
        class: 'deletions'
        x:0
        y:     (f, i) -> i * 21
        height: 20
        width: 0
      .transition()
      .delay((d, i) -> (i / files.length * settings.duration)+500 )
      .attr
        x: (f) -> scale(f[1])
        width: (f, i) -> scale(f[2])
    # deletions.exit().remove()

$.getJSON Repo.url, Repo.add_commits
window.t = timeline_chart
