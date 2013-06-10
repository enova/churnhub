#= require d3
#Array.prototype.inject = (init, fn) -> this.reduce(fn, init)
filter = () -> 
  a = $('#filter').val()
  window.Repo.filter(a)
  window.Repo.update()

$('#filter').on("input",filter)

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
    Repo.commits = Repo.commits.concat(commits)
    Repo.add_files commit.files for commit in commits
    Repo.format_files()
    Repo.draw()
    Repo.animate()
    Repo.set_labels()

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
