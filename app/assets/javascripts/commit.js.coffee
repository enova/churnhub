class window.Timeline
  recalculate: ->
    @width  = @$el.width()
    @height = @$el.height()
    @rx     = d3.scale.linear().domain([0, @width])
    @x      = d3.scale.linear().range([0, @width])
    @y      = d3.scale.linear().range([@height, 0])

  get_timestamp:            (commit) -> commit.timestamp
  get_aggregated_additions: (commit) -> commit.aggregated_additions or 0
  get_aggregated_deletions: (commit) -> commit.aggregated_deletions or 0

  stack:      d3.layout.stack().offset("zero")
  parse_date: d3.time.format("%Y-%m-%dT%XZ").parse

  summed_additions_deletions: (d) => @get_aggregated_additions(d) + @get_aggregated_deletions(d)

  constructor: (@$el) ->
    @recalculate()

    @layer = (commits) =>
      deletions = ({x: commit.pos, y: @get_aggregated_additions(commit), y0: 0} for commit in commits)
      additions = ({x: commit.pos, y: @get_aggregated_deletions(commit), y0: @get_aggregated_additions} for commit in commits)

      @stack [deletions, additions]

    @area = d3.svg.area().x((d) => @x d.x).y0((d) => @y d.y0).y1((d) => @y d.y + d.y0)

    @get_timestamp_range = (min_screen_x, max_screen_x) =>
      a = Math.floor @rx(min_screen_x)
      b = Math.ceil  @rx(max_screen_x)
      [@filtered_commits[a].timestamp, @filtered_commits[b].timestamp]
    @sort_timestamp_asc = (a,b) => a.timestamp - b.timestamp

    @svg = d3.select(@$el.selector)
      .append("svg").attr
        class: "timeline_chart_svg"
        width: @width
        height: @height
    @render = (filtered_commits) =>
      for commit, i in filtered_commits
        commit.pos = i if commit?
      @filtered_commits = filtered_commits

      @svg.selectAll("path").remove()
      @svg.selectAll("g").remove()
      @x.domain [0 , filtered_commits.length]
      @y.domain [0, d3.max(filtered_commits, @summed_additions_deletions)]
      @rx.range [0 , filtered_commits.length - 1]
      a = @svg.selectAll(".area").data(@layer filtered_commits)

      a.enter()
        .append("g").attr
          class: "area"
        .append("path").transition().attr
          d: @area
          class: (d, i) -> if i is 0 then "additions" else "deletions"

      c = @svg.selectAll(".point").data(filtered_commits)
      c.enter()
        .append("g")
        .attr("class", "point")
        .append("circle")
        .attr
          class: "deletions"
          r: 5
          cx: (d) =>
            @x d.pos
          cy: (d) =>
            @y @get_aggregated_deletions(d) + @get_aggregated_additions(d)
        .append("title")
        .text (d) -> d.timestamp
      c.exit().remove()

window.timeline_chart = new Timeline($("#timeline"))

do ->

  ls         = $('.left.slider')
  rs         = $('.right.slider')
  $highlight = $("#highlight")
  rs_down    = ls_down = false
  width      = $("#timeline").width()
  current = []
  timeout = false
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
    temp = timeline_chart.get_timestamp_range(ls.offset().left || 0 , rs.offset().left)
    if not _.isEqual(current, temp)
      current = temp
      clearTimeout(timeout)
      timeout = setTimeout ->
        Repo.display_with_filtered_commits Repo.commits.filter (commit) ->
          commit.timestamp >= current[0] and commit.timestamp <= current[1]
      , 50

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

    Repo.parsed_files++
    Repo.progress_text.text("Loaded #{Repo.parsed_files} of #{Repo.num_commits}")
    Repo.progress_bar.css("width", Repo.parsed_files / Repo.num_commits * 100+"%")
    # debugger if Repo.parsed_files > 10
    if(Repo.parsed_files == Repo.num_commits)
      Repo.pure_form.show()
      Repo.progress_bar.hide()
      Repo.progress_text.hide()
      Repo.progress_container.hide()
      Repo.render_barchart()

  render_barchart: ->
    console.log("render bar")
    Repo.format_files()
    Repo.draw()
    Repo.animate()
    Repo.set_labels()

  render_timeline: ->
    timeline_chart.render Repo.commits.sort(timeline_chart.sort_timestamp_asc)

  init: (commits) ->
    Repo.num_commits = commits.length
    Repo.parsed_files = 0
    Repo.pure_form = $(".pure-form")
    Repo.progress_container = $("#progress-container")
    Repo.progress_text = $("#progress-text")
    Repo.progress_bar = $("#progress-bar")
    Repo.progress_container.show()
    Repo.progress_text.show()
    Repo.progress_bar.show()
    Repo.pure_form.hide()

    for commit in commits
      if commit.files?
        Repo.parse_commit(commit)
      else
        $.getJSON window.location.origin + "/commits/#{commit.id}.json", Repo.parse_commit
    Repo.render_timeline() if Object.keys(Repo.commits).length > 0

    timeline_chart.render Repo.commits
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
    scale = d3.scale.log().base(10).domain([0.1, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width])
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

  find_index_of: (name, files_array) ->
    for i in [0...files_array.length] by 1
      if(name is files_array[i][0])
        return i
    return -1

  move_to_new_position: ->
    #Repo.prepared_files.indexOf(Repo.chart.selectAll("rect.deletions")[0][i].__data__) * 23
    Repo.chart.selectAll("rect.deletions")
      .attr
        visibility: (f) -> if Repo.find_index_of(f[0], Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .attr
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files)* settings.lineheight


    Repo.chart.selectAll("rect.additions")
      .attr
        visibility: (f) -> if Repo.find_index_of(f[0], Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .attr
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files)* settings.lineheight

    Repo.chart.selectAll("text.bar-label")
      .attr
        visibility: (f) -> if Repo.find_index_of(f[0], Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("text.bar-label")
      .transition(settings.duration)
      .attr
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files)* settings.lineheight + 17

  filter: (text) ->
    Repo.temp_filtered = []
    for i in [0...Repo.prepared_files.length] by 1
      if Repo.prepared_files[i][0].indexOf text != -1
        Repo.temp_filtered.push(Repo.prepared_files[i])
    console.log(Repo.prepared_files)
    Repo.prepared_files = temp_filtered
    Repo.move_to_new_position()
    Repo.set_labels()

  correct_object: (f) -> 
    index = Repo.find_index_of(f[0], Repo.prepared_files)

    console.log(index + " " + f[0])
    return Repo.prepared_files[index]

  display_with_filtered_commits: (filtered_commits) ->
    scale = d3.scale.log().base(10).domain([0.1, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width])

    console.log("asdf" + filtered_commits)
    Repo.files = []
    for commit in filtered_commits
      for file in commit.files
        name = file[0]
        Repo.files[name]   or= [0, 0]
        Repo.files[name][0] += file[1]
        Repo.files[name][1] += file[2]
    console.log(Repo.files)
    temp_files = ([name, f[0], f[1], f[0]+f[1]] for name, f of Repo.files)
    Repo.prepared_files = temp_files.sort (a,b) -> (b[3] - a[3])
    console.log(Repo.prepared_files)
    Repo.move_to_new_position()

    console.log(Repo.correct_object(Repo.prepared_files[1]))
    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .delay((d, i) -> (settings.duration))
      .attr
        x: (f, i) -> 
          file = Repo.correct_object(f)
          return 0 if file is undefined
          if file[3] is 0 then 0 else scale(file[3])*file[1]/file[3]
        width: (f, i) -> 
          file = Repo.correct_object(f)
          return 0 if file is undefined
          if file[3] is 0 then 0 else scale(file[3])*file[2]/file[3]

    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .delay((d, i) -> (settings.duration))
      .attr
        width: (f, i) -> 
          file = Repo.correct_object(f)
          return 0 if file is undefined
          if file[3] is 0 then 0 else scale(file[3])*file[1]/file[3]


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
