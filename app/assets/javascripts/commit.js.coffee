#= require helpers
class window.Timeline
  recalculate: ->
    @width  = @$el.innerWidth()
    @height = @$el.innerHeight()
    @x      = d3.scale.linear().range([0, @width])
    @rx     = d3.scale.linear().domain([0, @width])
    @y      = d3.scale.pow().exponent(.3).range([@height, 0])
    @ry     = d3.scale.pow().exponent(.3).domain([@height, 0])

    @x.domain [0 , Repo.num_commits - 1]
    @rx.range [0 , Repo.num_commits - 1]

  get_timestamp:            (commit) -> commit.timestamp
  get_aggregated_additions: (commit) -> commit.aggregated_additions or 0
  get_aggregated_deletions: (commit) -> commit.aggregated_deletions or 0
  get_filename:            (file) -> file.filename
  get_additions:           (file) -> file.additions
  get_deletions:           (file) -> file.deletions

  stack:      d3.layout.stack().offset("zero")
  parse_date: d3.time.format("%Y-%m-%dT%XZ").parse
  $tooltip:    $("#commit-tooltip")
  draw_tooltip: (e) =>
    return false if not @filtered_commits?
    x = e.pageX
    clearTimeout @tooltip_timeout
    @$tooltip.fadeIn()

    commit = @filtered_commits[Math.round(@rx(x))]

    @$tooltip.html [
      d3.time.format("<b>%c</b>")(commit.timestamp),
      commit.sha,
      'Additions: ' + commit.aggregated_additions,
      'Deletions: ' + commit.aggregated_deletions
      'Changes: '   + (commit.aggregated_additions + commit.aggregated_deletions)
    ].join("<br>")

    tooltip_width = @$tooltip.width()
    rounded_x = @x(Math.round(@rx(x)))

    @tooltip_timeout = setTimeout(((e) => @$tooltip.fadeOut()), 3000)

    $("#x-marker").css
      left: rounded_x
    @$tooltip.css
      left: (rounded_x - tooltip_width / 2).clip(30, @width - tooltip_width - 30)


  summed_additions_deletions: (commit) => @get_aggregated_additions(commit) + @get_aggregated_deletions(commit)
  set_aggregate_values: (commit, filter_text) =>
    commit.aggregated_additions = d3.sum(commit.files, (file) => if file.filename.matches(filter_text) then file.additions else 0)
    commit.aggregated_deletions = d3.sum(commit.files, (file) => if file.filename.matches(filter_text) then file.deletions else 0)

  constructor: (@$el) ->
    @recalculate()
    @$el.on('mousemove', @draw_tooltip)

    @layer = (commits) =>
      deletions = ({x: commit.pos, y: @get_aggregated_additions(commit), y0: 0} for commit in commits)
      additions = ({x: commit.pos, y: @get_aggregated_deletions(commit), y0: @get_aggregated_additions(commit)} for commit in commits)
      @stack [deletions, additions]

    @area = d3.svg.area().x((d) => @x d.x).y0((d) => @y d.y0).y1((d) => @y d.y + d.y0)

    @get_timestamp_range = (min_screen_x, max_screen_x) =>
      return false if not @filtered_commits?
      a = Math.round @rx(min_screen_x)
      b = Math.round @rx(max_screen_x)
      [@filtered_commits[a].timestamp, @filtered_commits[b].timestamp]

    @sort_timestamp_asc = (a, b) => a.timestamp - b.timestamp

    @svg = (d3.select(@$el.selector)
      .append("svg").attr
        class: "timeline_chart"
        width: @width
        height: @height)

    @render = (commits, filter_text="") =>
      if not @filter_text? or (not @filter_text is filter_text) or not @filtered_commits
        for commit, i in commits
          @set_aggregate_values(commit, filter_text)
          commit.pos = i if commit?
        @filtered_commits = commits
        t = d3.max(@filtered_commits, @summed_additions_deletions)
        @y.domain [0, t]
        @ry.range [0 , t]
      a = @svg.selectAll(".area").data(@layer @filtered_commits)
      a.transition()
        .duration(100)
        .attr
          d: @area
      a.enter()
        .append("path")
        .attr
          d: @area
          class: (d, i) -> if i is 0 then "additions area" else "deletions area"
      a.exit()
        .remove()


do ->
  ls         = $('.left.slider')
  rs         = $('.right.slider')
  $highlight = $("#highlight")
  rs_down    = ls_down =   false
  mid_down = null
  previous_x = 0
  width      = $("#timeline").innerWidth()
  current = []
  timeout = false

  moved = (e) ->
    x = e.pageX - 10
    if ls_down
      x = x.clip(0, rs.offset().left - 20)
      $highlight.css left: x
      $(".lowlight.left").css width: x
      ls.css         left: x
    if rs_down
      x = x.clip(ls.offset().left + 20, width - 20)
      $highlight.css right: width - x - 20
      $(".lowlight.right").css width: width - x - 20
      rs.css          left: x
    if mid_down
      x = e.pageX
      previous_x or= x
      diff = x - previous_x

      diff = diff.clip(-ls.offset().left, width - rs.offset().left - 20)

      $highlight.css left: "+=#{diff}", right: "-=#{diff}"
      ls.css left: "+=#{diff}"
      rs.css left: "+=#{diff}"
      previous_x = x
      $(".lowlight.right").css width: "-=#{diff}"
      $(".lowlight.left").css width: "+=#{diff}"

    if timeline_chart?
      temp = timeline_chart.get_timestamp_range(ls.offset().left || 0 , rs.offset().left)
      previous_x = x
      if not _.isEqual(current, temp)
        current = temp
        clearTimeout(timeout)
        timeout = setTimeout ->
          Repo.display_with_filtered_commits Repo.commits.filter (commit) ->
            commit.timestamp >= current[0] and commit.timestamp <= current[1]
        , 200

  ls.on 'mousedown', (e) ->
    e.preventDefault()
    ls_down = true
  rs.on 'mousedown', (e) ->
    e.preventDefault()
    rs_down = true
  $("#highlight").on 'mousedown', (e) ->
    e.preventDefault()
    mid_down = true

  $(document).on('mousemove', moved).on 'mouseup mouseenter', ->
    rs_down = ls_down = mid_down = false

settings =
  width: $("#graph_chart").innerWidth()
  height: 500
  duration: 500
  lineheight: 23
  linespacing: 5
  padding: 20

settings.offset = settings.width * 0.3


window.Repo =
  chart: d3.select("#graph_chart").append("svg").attr
    class: 'chart'
    width: settings.width
    height: settings.height
  commits: []
  url:     window.location.pathname + ".json"
  files:   {}
  formated_files: []

  parse_commit: (commit)->
    Repo.add_files commit.files
    Repo.timestamp_to_d3 commit
    Repo.commits = Repo.commits.concat(commit)
    Repo.render_timeline()

    Repo.parsed_files++

    $("#filter").hide()
    Repo.$progress.css display: 'inline-block'
    Repo.$progress.find('.text').text("#{Repo.parsed_files} of #{Repo.num_commits}")
    Repo.$progress.find('.bar').css 'width', Repo.parsed_files / Repo.num_commits * 100 + "%"

    if Repo.parsed_files is Repo.num_commits
      $(".blurred").removeClass("blurred")
      Repo.$progress.hide()
      $("#filter").show()
      Repo.render_barchart()

  render_barchart: ->
    Repo.format_files()
    Repo.draw()
    Repo.animate()

  render_timeline: ->
    timeline_chart.render Repo.commits.sort(timeline_chart.sort_timestamp_asc), $('#filter').val()

  init: (commits) ->
    Repo.num_commits = commits.length
    Repo.parsed_files = 0
    Repo.$progress = $("#progress")
    window.timeline_chart = new Timeline($("#timeline"))

    for commit in commits
      if commit.timestamp?
        Repo.parse_commit(commit)
      else
        $.getJSON window.location.origin + "/commits/#{commit.id}.json", Repo.parse_commit

    Repo.render_timeline() if Object.keys(Repo.commits).length > 0

    timeline_chart.render Repo.commits
    Repo.add_files commit.files
    Repo.timestamp_to_d3 commit

  timestamp_to_d3: (commit) ->
    commit.timestamp = d3.time.format("%Y-%m-%dT%XZ").parse(commit.timestamp) if typeof commit.timestamp is "string"

  calculate_files_of: (commit) ->
    commit.aggregated_additions = d3.sum(commit.files, (file)-> file.additions)
    commit.aggregated_deletions = d3.sum(commit.files, (file)-> file.deletions)

  add_files: (files) ->
    return if not files?
    for file in files
      name = file.filename
      Repo.files[name]   or= {additions: 0, deletions: 0}
      Repo.files[name].additions += file.additions
      Repo.files[name].deletions += file.deletions

  format_files: ->
    Repo.formated_files = for name, file of Repo.files
      {
        filename:  name,
        additions: file.additions,
        deletions: file.deletions,
        changes:   file.additions + file.deletions
      }

  sort_files: ->
    Repo.formated_files.sort (file1, file2) -> (file2.changes - file1.changes)
    Repo.prepared_files = Repo.formated_files

  draw: ->
    Repo.chart.attr
      height: Repo.formated_files.length * (settings.lineheight + settings.linespacing)

    Repo.sort_files()
    changes = Repo.chart.selectAll("rect").data(Repo.formated_files).enter().append("g").attr("class", "changes")
      .append("svg:title")
      .text((file) -> file.filename)

    additions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'additions'
        x: settings.offset
        y:     (file, i) -> i * (settings.lineheight + settings.linespacing)
        width: 0
        height: settings.lineheight

    deletions = Repo.chart.selectAll("g").data(Repo.formated_files).append("rect")
      .attr
        class: 'deletions'
        x: settings.offset
        y:     (f, i) -> i * (settings.lineheight + settings.linespacing)
        height: settings.lineheight
        width: 0

    bar_labels = Repo.chart.selectAll("g").data(Repo.formated_files).append("text")
      .text((file, i) -> file.changes).attr
        class: "bar-label"
        x: settings.offset + 5
        y: (f, i) -> i * (settings.lineheight + settings.linespacing) + 17

    bar_name_labels = Repo.chart.selectAll("g").data(Repo.formated_files).append("text")
      .text((file, i) -> file.filename).attr
        class: "bar-name-label"
        x: settings.offset - settings.padding
        width: settings.offset
        y: (file, i) -> i * (settings.lineheight + settings.linespacing) + 16

  animate: -> #called after the original draw function and will animate everything into place.
    scale = Repo.get_scale()
    console.log(scale)

    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .delay((file, i) -> (i / Repo.formated_files.length * settings.duration) )
      .attr
        x: (file) -> if file.changes is 0 then settings.offset else scale(file.changes) * file.additions / file.changes + settings.offset
        width: (file, i) -> if file.changes is 0 then 0 else scale(file.changes) * file.deletions / file.changes

    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .delay((file, i) -> (i / Repo.formated_files.length * settings.duration))
      .attr
        width: (file, i) -> if file.changes is 0 then 0 else scale(file.changes) * file.additions / file.changes

  find_index_of: (name, files_array) ->
    for file, i in files_array
      if(name is file.filename)
        return i
    return -1

  move_to_new_position: ->
    Repo.chart.selectAll("rect.deletions")
      .attr
        visibility: (file) -> if Repo.find_index_of(file.filename, Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .attr
        y: (file, i) -> Repo.find_index_of(file.filename, Repo.prepared_files) * (settings.lineheight + settings.linespacing)


    Repo.chart.selectAll("rect.additions")
      .attr
        visibility: (file) -> if Repo.find_index_of(file.filename, Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .attr
        y: (f, i) -> Repo.find_index_of(f.filename, Repo.prepared_files) * (settings.lineheight + settings.linespacing)

    Repo.chart.selectAll("text.bar-label")
      .attr
        visibility: (f) -> if Repo.find_index_of(f.filename, Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("text.bar-label")
      .transition(settings.duration)
      .attr
        y: (f, i) -> Repo.find_index_of(f.filename, Repo.prepared_files)* (settings.lineheight + settings.linespacing) + 17

    Repo.chart.selectAll("text.bar-name-label")
      .attr
        visibility: (f) -> if Repo.find_index_of(f.filename, Repo.prepared_files) is -1 then "hidden" else ""
    Repo.chart.selectAll("text.bar-name-label")
      .transition(settings.duration)
      .attr
        y: (f, i) -> Repo.find_index_of(f.filename, Repo.prepared_files)* (settings.lineheight + settings.linespacing ) + 17

  filter: (text, files) ->
    (file for file in files when file.filename.matches(text) and not _(Repo.excluded_files).contains(file))

  correct_object: (f) ->
    index = Repo.find_index_of(f.filename, Repo.prepared_files)
    return Repo.prepared_files[index]

  display_with_filtered_commits: (filtered_commits) ->
    Repo.files = []
    for commit in filtered_commits
      for file in commit.files
        name = file.filename
        Repo.files[name]   or= {additions: 0, deletions: 0}
        Repo.files[name].additions += file.additions
        Repo.files[name].deletions += file.deletions
    Repo.saved_files = for name, file of Repo.files
      {
        filename:  name
        additions: file.additions
        deletions: file.deletions
        changes:   file.deletions + file.additions
      }

    Repo.display_with_filtered_commits_and_text_filter(f.val())

  get_scale: () ->
    return d3.scale.pow().exponent(.5).domain([0.1, d3.max(Repo.prepared_files, (f)-> f.changes )]).range([0, settings.width - settings.offset - 2 * settings.padding])

  display_with_filtered_commits_and_text_filter: (text) ->
    Repo.prepared_files = Repo.filter(text, Repo.saved_files)

    Repo.prepared_files = Repo.prepared_files.sort (file1, file2) -> (file2.changes - file1.changes)

    Repo.move_to_new_position()
    scale = Repo.get_scale()
    Repo.chart.selectAll("text.bar-label")
      .text (file) ->
        file = Repo.correct_object(file)
        return "" if file is undefined
        return file.changes

    Repo.chart.selectAll("rect.deletions")
      .transition(settings.duration)
      .delay((f, i) -> (settings.duration))
      .attr
        x: (f, i) ->
          file = Repo.correct_object(f)
          return settings.offset if file is undefined
          if file.changes is 0 then settings.offset else scale(file.changes) * file.additions / file.changes + settings.offset
        width: (file, i) ->
          file = Repo.correct_object(file)
          return 0 if file is undefined
          if file.changes is 0 then 0 else scale(file.changes) * file.deletions / file.changes

    Repo.chart.selectAll("rect.additions")
      .transition(settings.duration)
      .delay((file, i) -> (settings.duration))
      .attr
        width: (file, i) ->
          file = Repo.correct_object(file)
          return settings.offset if file is undefined
          if file.changes is 0 then 0 else scale(file.changes) * file.additions / file.changes

    Repo.chart.attr
      height: Repo.prepared_files.length * (settings.lineheight + settings.linespacing)


$.getJSON Repo.url, Repo.init
$(window).resize ->
  timeline_chart.recalculate()
  Repo.render_timeline()

f = $('#filter')

filter = ->
  a = f.val()
  console.log "called input", a
  Repo.display_with_filtered_commits_and_text_filter(a)
  timeline_chart.recalculate()
  timeline_chart.render(Repo.commits, a)

f.on("input", filter)
$(document).on 'click', '.additions', (e) -> console.log 'hi'
