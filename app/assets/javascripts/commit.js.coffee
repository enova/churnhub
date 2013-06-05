#= require d3

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
    Repo.commits = Repo.commits.concat(commits)
    Repo.add_files commit.files for commit in commits
    Repo.draw()

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
