// vim: set ts=2 sw=2 :
(function(){
  'use strict';

  angular.module('vv.ui.labLines', [
    'vv.ui'
  ])
  .component('labLines', {
    templateUrl: viroverse.url_base + '/static/partials/lab-lines.html',
    controller: controller,
    controllerAs: 'c',
    bindings: {
      width:       '=width',
      panelHeight: '=height',
      values:      '=?values',
      valuesJson:  '@?valuesJson',
      facetField:  '@facet',
      xField:      '@x',
      yField:      '@y',
      xTitle:      '@?xTitle',
      yTitleField: '@?yTitle'
    }
  });

  controller.$inject = ['$log'];

  function controller($log) {
    this.$log = $log;
  }

  controller.prototype.$onInit = function() {
    this.$log.debug("Initializing lab lines:", angular.copy(this));

    // Defaults
    this.xTitle = this.xTitle || this.xField;


    // Field accessors
    this.xValue = dl.accessor(this.xField);
    this.yValue = dl.accessor(this.yField);
    this.facet  = dl.accessor(this.facetField);
    this.yTitle = dl.accessor(this.yTitleField) || function(){ return "" };


    // Data
    if (!this.values && !this.valuesJson)
      return;

    this.values = dl.read(
      this.values || this.valuesJson, {
        type: "json",
        parse: {
          [this.xField]:     "date:'%Y-%m-%d'",
          [this.yField]:     "number",
          [this.facetField]: "string"
        }
      }
    );

    this.panels = dl.groupby(this.facet)
      .execute(this.values);


    // Dynamic dimensions and margins
    this.panelSpacing = 30;
    this.height       = (this.panelHeight + this.panelSpacing) * this.panels.length;

    let maxValue  = dl.max(this.values, this.yValue),
        maxDigits = Math.floor(Math.log10(maxValue)) + 1;

    this.margin = {
      top: 50,
      right: 10,
      bottom: 30,
      left: dl.max([30, maxDigits * 10])   // At least 30px
    };


    // Shared x scale and scaled x value function
    let xDomain = d3.extent(this.values, this.xValue);

    this.xScale = d3.time.scale.utc()
      .domain(xDomain)
      .range([0, this.width]);

    this.xTicks = this.xScale.ticks();

    this.x = angular.bind(this,
      function(d){ return this.xScale(this.xValue(d)) });


    // Construct scaling functions for each facet panel
    this.panels = this.panels.map(function(panel) {

      // Viral loads use a log scale, which needs special treatment, and also
      // get some labeling/styling special casing.
      panel.isViralLoad = this.facet(panel) === 'Viral load';


      // Extent of data for determining domain and marking min/max points
      panel.yExtent         = dl.extent(panel.values, this.yValue);
      panel.markExtentIndex = (panel.values.length > 2 && panel.yExtent[0] != panel.yExtent[1])
        ? dl.extent.index(panel.values, this.yValue)
        : [];


      // Scale for each panel, where the domain always includes 0.
      let yDomain = [
        dl.min([0, panel.yExtent[0]]),
        dl.max([0, panel.yExtent[1]])
      ];

      // This should only happen when all the data points are 0.
      if (yDomain[0] === yDomain[1])
        yDomain[1] = yDomain[0] + 1;

      // Log scales can't include zero, so use a reasonable starting point.
      if (panel.isViralLoad)
        yDomain[0] = 10;

      let scale = panel.isViralLoad
        ? d3.scale.log()
        : d3.scale.linear();

      panel.yScale = scale
        .domain(yDomain)
        .range([this.panelHeight, 0]);


      // Formatting functions for data values and axis ticks
      panel.formatValue = d3.format(",");
      panel.formatTick = panel.isViralLoad
        ? d3.format(",.0")
        : panel.yScale.tickFormat();


      // Scaled y value accessor function
      panel.y = angular.bind(this,
        function(_){ return panel.yScale(this.yValue(_)) });


      // Line drawing function
      panel.line = d3.svg.line()
        .x(this.x)
        .y(panel.y)
        .interpolate("linear");

      return panel;
    }, this);
  };

  controller.prototype.closestPointToMouse = function(values, $event) {
    // The idea here is to convert the mouse position to an x value (a date),
    // bisect the plotted values to find the two points on either side of the
    // mouse, and then figure out which of those two data points is closest to
    // the mouse position.  This is based on examples by Mike Bostock, of D3.js.
    let target     = $event.target,
        targetRect = target.getBoundingClientRect(),
        mouseX     = $event.clientX - targetRect.left - target.clientLeft,
        mouseDate  = this.xScale.invert(mouseX),
        index      = d3.bisector(this.xValue).left(values, mouseDate),
        d0         = values[index - 1],
        d1         = values[index];

    return (d1 && (!d0 || (mouseDate - this.xValue(d0) > this.xValue(d1) - mouseDate)))
      ? d1 : d0;
  };

})();
