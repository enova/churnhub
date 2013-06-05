#= require d3

Array.prototype.inject = (init, fn) -> this.reduce(fn, init)
settings = 
  width: 420
  height: 500

Repo =
  chart: d3.select("#chart").append("svg").attr
    class: 'chart'
    width: settings.width
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
    changes = (f[0]+f[1] for name, f of Repo.files)
    scale   = d3.scale.linear().domain([0, d3.max(changes)]).range([0, settings.width])
    changes = Repo.chart.selectAll("rect").data(files).enter().append("g")
    additions = Repo.chart.selectAll("g").data(files).insert("rect")
      .attr
        class: 'additions'
        y:     (f, i) -> i * 21
        width: (f, i) -> scale(f[1])
        height: 20
    deletions = Repo.chart.selectAll("g").data(files).insert("rect")
      .attr
        class: 'deletions'
        data: (f) -> f[0]
        y:     (f, i) -> i * 21
        x: (f) -> scale(f[1])
        width: (f, i) -> scale(f[2])
        height: 20
    # deletions.exit().remove()

$.getJSON Repo.url, Repo.add_commits
