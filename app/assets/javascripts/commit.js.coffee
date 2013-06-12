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
    top: 0
    right: 0
    bottom: 0
    left: 20
  t.get_timestamp = (commit) -> commit.timestamp
  t.get_aggregated_additions = (commit) -> commit.aggregated_additions || 0
  t.get_aggregated_deletions = (commit) -> commit.aggregated_deletions || 0
  t.width = (window.innerWidth) - t.margin.left - t.margin.right
  t.height = 100 - t.margin.top - t.margin.bottom
  t.parse_date = d3.time.format("%Y-%m-%dT%XZ").parse
  t.rx = d3.scale.linear().domain([0, t.width])
  t.x = d3.scale.linear().range([0, t.width])
  t.y = d3.scale.linear().range([t.height, 0])
  t.stack = d3.layout.stack().offset("wiggle")
  t.layer = (commits) -> t.stack [({x: commit.pos, y: t.get_aggregated_additions(commit)} for commit in commits), ({x: commit.pos, y: t.get_aggregated_deletions(commit)} for commit in commits)]
  t.get_timestamp_range = (min_screen_x, max_screen_x) -> 
    a = Math.floor(t.rx min_screen_x)
    b = Math.ceil(t.rx max_screen_x)
    [t.filtered_commits[a].timestamp, t.filtered_commits[b].timestamp]

  # t.x_axis = d3.svg.axis().scale(t.x).orient("bottom")
  # t.y_axis = d3.svg.axis().scale(t.y).orient("left")  
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
    t.filtered_commits = filtered_commits
    t.svg.selectAll("path").remove()
    t.svg.selectAll("g").remove()
    t.x.domain [0 , filtered_commits.length]
    t.rx.range [0 , filtered_commits.length]
    t.y.domain [0, d3.max(filtered_commits, t.summed_additions_deletions)]
    a = t.svg.selectAll(".area").data([filtered_commits])
    a.enter()
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
    # .exit().remove
    c = t.svg.selectAll(".point").data(filtered_commits)
    c.enter()
      .append("g")
      .attr("class", "point")
      .append("circle")
      .transition()
      .attr 
        r: 2
        cx: (d) -> 
          t.x d.pos
        cy: (d) ->
          t.y t.get_aggregated_deletions(d) + t.get_aggregated_additions(d)
    c.exit().remove()


    # a.append("g")
    #   .attr
    #     class: "x axis"
    #     transform: "translate(0," + t.height + ")"
    #   .call t.x_axis
    # a.append("g")
    #   .attr
    #     class: "y axis"
    #   .call(t.y_axis)
  return t

do ->
  ls = $('.left.slider')
  rs = $('.right.slider')
  max_width = $('#timeline>svg').innerWidth() - timeline_chart.margin.right - 10
  min_width = timeline_chart.margin.left
  ls_down = false
  rs_down = false
  down = (e)-> 
    ls_down = true if (e.data is ls)
    rs_down = true if (e.data is rs)
          
  up = (e)->
    ls_down = false 
    rs_down = false
    console.log timeline_chart.get_timestamp_range parseInt(ls.css("left")) || min_width, parseInt(rs.css("left")) || max_width

  moved = (e) -> 
    ls.css("left", e.pageX-2.5) if ls_down and e.pageX+5 < (parseInt rs.css("left")) and e.pageX < max_width and e.pageX > min_width
    rs.css("left", e.pageX-2.5) if rs_down and e.pageX-5 > (parseInt ls.css("left")) and e.pageX < max_width and e.pageX > min_width
  ls.on 'mousedown', ls, down
  rs.on 'mousedown', rs, down
  $(document).on('mouseup', up).on('mousemove', moved).on('mouseenter', up)


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

  parse_commit: (commit)->
    Repo.add_files commit.files
    Repo.calculate_files_of commit
    Repo.timestamp_to_d3 commit
    Repo.commits = Repo.commits.concat(commit)
    clearTimeout(Repo.timer)
    Repo.timer = setTimeout (->
      console.log "called render charts"
      Repo.render_charts()
    ), 400
    # Repo.render_charts()

  render_charts: ->
    # Repo.format_files()
    # Repo.draw()
    # Repo.animate()
    # Repo.set_labels()
    # Repo.commits.sort(timeline_chart.sort_timestamp_asc)
    timeline_chart.render_timeline_chart (c for c in Repo.commits when c.aggregated_deletions? and c.aggregated_additions? and c.timestamp?).sort(timeline_chart.sort_timestamp_asc)

  init: (commits) ->
    for commit in commits
      if commit.files?
        Repo.parse_commit(commit)
      else
        $.getJSON window.location.origin + "/commits/#{commit.id}.json", Repo.parse_commit
    Repo.render_charts() if Object.keys(Repo.commits).length > 0

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

$.getJSON Repo.url, Repo.init
window.t = timeline_chart
