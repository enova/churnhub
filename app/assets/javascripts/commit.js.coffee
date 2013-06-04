#= require d3

Array.prototype.inject = (init, fn) -> this.reduce(fn, init)

Repo =
  chart: d3.select("#chart").append("svg").attr
    class: 'chart'
    width: 420
    height: 500
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
    files   = ([name, f[0], f[1]] for name, f of Repo.files)
    changes = (f[1] + f[2] for f in files)
    scale   = d3.scale.linear().domain([0, d3.max(changes)]).range([0, 420])
    rect    = Repo.chart.selectAll("rect").data(files)

    rect.enter().append("rect")
      .attr
        y:     (f, i) -> i * 20
        width: (f, i) -> scale(f[1] + f[2])
        height: 20

    rect.exit().remove()

$.getJSON Repo.url, Repo.add_commits
