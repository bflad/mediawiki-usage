
function init(){          
  jQuery(function(){
    var dataTable = null, // will contain the dataTable later
      sources = {
        'day': 'http://moon.wharton.upenn.edu/mediawiki-usage/count/day',
        'hour': 'http://moon.wharton.upenn.edu/mediawiki-usage/count/hour',
        'editors': 'http://moon.wharton.upenn.edu/mediawiki-usage/editors',
        'pages' : 'http://moon.wharton.upenn.edu/mediawiki-usage/pages'
      };
  
    function googInit () {
      dataTable = new google.visualization.DataTable();
    
      dataTable.addColumn('string', 'Category');
      dataTable.addColumn('number', 'Edits');

      loadData();
    }

    function getChartType() {
      var chartType = $("#chart-type .selected").html();
      return chartType == "Table" ? chartType : chartType + "Chart";
    }

    function getDataType() {
      return $("#data-type .selected").html().toLowerCase();
    }

    function jsonToPie(data) {
      var rtn = [];
      jQuery.each(data, function(index, hash) {
        for(var prop in hash) {
          rtn.push([prop, {v: hash[prop], f: hash[prop] + ' changes'}]);
        }
      });
      return rtn;
    }
  
    function loadData(){
      var queryVars = {
        start: getUnixTime($('#startTime').val()),
        end: getUnixTime($('#endTime').val())
      },
      jsonSource = sources[getDataType()] + '?' + $.param(queryVars) +
        '&callback=?';
      $.getJSON( jsonSource, function(data) {
        // clear data table
        if (data){
          dataTable.removeRows(0, dataTable.getNumberOfRows());
          dataTable.addRows(jsonToPie(data));
          delayDrawVisualization ();
        }
      });
    }
  
    
    function drawVisualization () {
      var visType = getChartType();
      new google.visualization[visType](
        $('#visualization')[0]).
          draw(dataTable, {is3D:true});
    }
    function delayDrawVisualization() {
      //drawVisualization (); // draw immediately.
      setTimeout(drawVisualization, 1000);
    }
  
    // http://www.electrictoolbox.com/unix-timestamp-javascript/
    function getUnixTime(dtm) {
      dtm = dtm || new Date();
      return Math.round(new Date(dtm).getTime() / 1000);
    }
  
    // when the chart type changes, redraw
    $("#chart-type").delegate("a", "click", function(e) {
      e.preventDefault();
      $(this).blur();
      $("#chart-type .selected").removeClass("selected");
      $(this).addClass("selected");
      delayDrawVisualization();
    });
    $("#data-type").delegate("a", "click", function(e) {
      e.preventDefault();
      $(this).blur();
      $("#data-type .selected").removeClass("selected");
      $(this).addClass("selected");
      loadData();
    });
  
    $('#endTime').val(Date.today().toString('MM/dd/yyyy'));
    $('#startTime').val(Date.today().add(-5).days().toString('MM/dd/yyyy'));
    $('input.date').datepicker({
      onSelect: function() { loadData() }
    });

    $('#visualization-container').resizable({
      stop: delayDrawVisualization,
      autoHide: true
    });
    
    // must follow all the inits, especially
    // default settings the end and start times
    googInit();
    delayDrawVisualization();
  });
}

// for the charts and data table
google.load('visualization', '1', {
  packages: [
    'piechart', 
    'barchart', 
    'columnchart', 
    'scatterchart', 
    'imagesparkline', 
    'table']
  }
);
  

google.setOnLoadCallback(init);