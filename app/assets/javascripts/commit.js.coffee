#= require d3

data  = [4, 8, 15, 16, 23, 42]
#

chart = d3.select('#chart').append("svg")
  .attr('class',  'chart')
  .attr('width',  "100%")
  .attr('height', 20 * data.length)

x = d3.scale.linear().domain([0, d3.max(data)]).range([0, 420])
chart.selectAll("rect")
 .data(data)
 .enter().append("rect")
   .attr("y", ((d, i) -> return i * 20; ))
   .attr("width", x)
   .attr("height", 20)
