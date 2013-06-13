class window.Commit
  constructor: (@attributes) ->
    for key, value of @attributes
      this[key] = value

class window.Chart

class window.Timeline extends Chart
  recalculate: ->
    @width  = @$el.width()
    @height = @$el.height()
    @x      = d3.scale.linear().range([0, @width])
    @rx     = d3.scale.linear().domain([0, @width])
    @y      = d3.scale.linear().range([@height, 0])
    @ry     = d3.scale.linear().domain([@height, 0])

  get_timestamp:            (commit) -> commit.timestamp
  get_aggregated_additions: (commit) -> commit.aggregated_additions or 0
  get_aggregated_deletions: (commit) -> commit.aggregated_deletions or 0

  stack:      d3.layout.stack().offset("zero")
  parse_date: d3.time.format("%Y-%m-%dT%XZ").parse

  # Good place to put this? Jeff
  $x_position: $("#x-position")
  $y_position: $("#y-position")
  draw_tooltip: (e) =>
    x = e.offsetX - 20
    y = e.offsetY
    @$y_position.text(Math.round(@ry(y)))
    @$x_position.text(JSON.stringify(@filtered_commits[Math.round(@rx(x))]))

  summed_additions_deletions: (d) => @get_aggregated_additions(d) + @get_aggregated_deletions(d)

  constructor: (@$el) ->
    @recalculate()
    @$el.on('mousemove', @draw_tooltip)

    @layer = (commits) =>
      deletions = ({x: commit.pos, y: @get_aggregated_additions(commit), y0: 0} for commit in commits)
      additions = ({x: commit.pos, y: @get_aggregated_deletions(commit), y0: @get_aggregated_additions} for commit in commits)

      @stack [deletions, additions]

    @area = d3.svg.area().x((d) => @x d.x).y0((d) => @y d.y0).y1((d) => @y d.y + d.y0)

    @get_timestamp_range = (min_screen_x, max_screen_x) =>
      return false if not @filtered_commits?
      a = Math.floor @rx(min_screen_x)
      b = Math.ceil  @rx(max_screen_x)
      [@filtered_commits[a].timestamp, @filtered_commits[b].timestamp]
    @sort_timestamp_asc = (a, b) => a.timestamp - b.timestamp

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
      t = d3.max(filtered_commits, @summed_additions_deletions)
      @x.domain [0 , filtered_commits.length]
      @y.domain [0, t]
      @rx.range [0 , filtered_commits.length - 1] # Question: Why -1
      @ry.range [0 , t] # Question: Why -1
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
  width: window.innerWidth
  height: 500
  duration: 500
  lineheight: 23
  offset: 500
  padding: 20


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

    $("#filter").hide()
    Repo.$progress.css display: 'inline-block'
    Repo.$progress.find('.text').text("#{Repo.parsed_files} of #{Repo.num_commits}")
    Repo.$progress.find('.bar').css 'width', Repo.parsed_files / Repo.num_commits * 100 + "%"

    if Repo.parsed_files is Repo.num_commits
      Repo.$progress.hide()
      $("#filter").show()
      Repo.render_barchart()

  render_barchart: ->
    Repo.format_files()
    Repo.draw()

  render_timeline: ->
    timeline_chart.render Repo.commits.sort(timeline_chart.sort_timestamp_asc)

  init: (commits) ->
    Repo.num_commits = commits.length
    Repo.parsed_files = 0
    Repo.$progress = $("#progress")

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

  add_commits: (commits) ->
    Repo.parsed_commits = 0
    for commit in Repo.commits
      if commit.files?
        Repo.parse_commit(commit)
      else
        $.getJSON window.location.origin + '/commits/' + commit.id + ".json", Repo.parse_commit

    Repo.render_timeline() if Object.keys(Repo.commits).length > 0

  timestamp_to_d3: (commit) ->
    commit.timestamp = d3.time.format("%Y-%m-%dT%XZ").parse(commit.timestamp) if typeof commit.timestamp is "string"

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
    Repo.chart.attr height: Repo.formated_files.length * 23

    textscale = d3.scale.linear().domain([0, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, 100])

    Repo.sort_files()
    changes = Repo.chart.selectAll("rect").data(Repo.formated_files).enter().append("g").attr("class", "changes")
      .append("svg:title")
      .text( (a) -> a[0])

    additions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'additions'
        x: settings.offset
        y:     (f, i) -> i * settings.lineheight
        width: 0
        height: settings.lineheight - 3

    deletions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'deletions'
        x: settings.offset
        y:     (f, i) -> i * settings.lineheight
        height: 20
        width: 0

    bar_labels = Repo.chart.selectAll("g").data(Repo.formated_files).append("text")
      .text((f, i) -> f[3]).attr
        class: "bar-label"
        x: settings.offset + 5
        y: (f, i) -> i * settings.lineheight + 17
        style: (f, i) -> "fill: " + (if f[3] is 0 then "#555" else "#fff")

    bar_name_labels = Repo.chart.selectAll("g").data(Repo.formated_files).append("text")
      .text((f, i) -> f[0]).attr
        class: "bar-name-label"
        x: settings.offset - settings.padding
        width: settings.offset
        y: (f, i) -> i * settings.lineheight + 17
        style: (f, i) -> "fill: #333"

    scale = d3.scale.log().base(10).domain([0.1, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width - settings.offset - 2 * settings.padding])
    Repo.chart.selectAll("rect.deletions")

      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration) )
      .attr
        x: (f) -> if f[3] is 0 then settings.offset else (scale(f[3])*f[1]/f[3] + settings.offset)
        width: (f, i) -> if f[3] is 0 then 0 else scale(f[3])*f[2]/f[3]

    Repo.chart.selectAll("rect.additions")

      .transition(settings.duration)
      .delay((d, i) -> (i / Repo.formated_files.length * settings.duration))
      .attr
        width: (f, i) -> if f[3] is 0 then 0 else scale(f[3])*f[1]/f[3]

  find_index_of: (name, files_array) ->
    for file, i in files_array
      return i if name is file[0]
    return -1

  move_to_new_position: ->
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
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files) * settings.lineheight + 17

    Repo.chart.selectAll("text.bar-name-label")
      .attr
        visibility: (f) -> if Repo.find_index_of(f[0], Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("text.bar-name-label")
      .transition(settings.duration)
      .attr
        y: (f, i) -> Repo.find_index_of(f[0], Repo.prepared_files)* settings.lineheight + 17

  filter: (text, array) ->
    (file for file in Repo.prepared_files when file[0].contains(text))

  correct_object: (f) ->
    index = Repo.find_index_of(f[0], Repo.prepared_files)
    return Repo.prepared_files[index]

  display_with_filtered_commits: (filtered_commits) ->
    Repo.files = []
    for commit in filtered_commits
      for file in commit.files
        name = file[0]
        Repo.files[name]   or= [0, 0]
        Repo.files[name][0] += file[1]
        Repo.files[name][1] += file[2]
    temp_files = ([name, fi[0], fi[1], fi[0]+fi[1]] for name, fi of Repo.files)
    Repo.saved_files = temp_files

    Repo.display_with_filtered_commits_and_text_filter(f.val())


  display_with_filtered_commits_and_text_filter: (text) ->

    scale = d3.scale.log().base(10).domain([0.1, d3.max(Repo.formated_files, (d)-> d[3] )]).range([0, settings.width - settings.offset - 2 * settings.padding])
    console.log(Repo.saved_files)
    Repo.prepared_files = Repo.filter(text, Repo.saved_files)
    console.log(Repo.prepared_files)

    Repo.prepared_files = Repo.prepared_files.sort (a,b) -> (b[3] - a[3])

    Repo.move_to_new_position()

    Repo.chart.selectAll("text.bar-label")
      .text (f) ->
        file = Repo.correct_object(f)
        return 0 if file is undefined
        f[3]

    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .delay((d, i) -> (settings.duration))
      .attr
        x: (f, i) ->
          file = Repo.correct_object(f)
          return settings.offset if file is undefined
          if file[3] is 0 then settings.offset else scale(file[3])*file[1]/file[3] + settings.offset

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
          return settings.offset if file is undefined
          if file[3] is 0 then 0 else scale(file[3])*file[1]/file[3]

    Repo.chart.attr
      height: Repo.prepared_files.length * 23


$.getJSON Repo.url, Repo.init
window.t = timeline_chart
$(window).resize ->
  timeline_chart.recalculate()
  Repo.render_timeline()
f = $('#filter')

filter = () ->
  a = f.val()
  console.log(a)
  window.Repo.display_with_filtered_commits_and_text_filter(a)

f.on("input",filter)
