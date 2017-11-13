<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->

    <script type="application/javascript" src="https://code.jquery.com/jquery-3.2.1.min.js"></script>

    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
          integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">

    <!-- Optional theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css"
          integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">

    <!-- Latest compiled and minified JavaScript -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"
            integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
            crossorigin="anonymous"></script>

    <!-- basic starter tenmplate -->
    <style type="text/css">
        body {
            padding-top: 50px;
        }

        .starter-template {
            padding: 40px 15px;
        }

        div.d3tooltip {
            position: absolute;
            text-align: center;
            width: 120px;
            height: 50px;
            padding: 2px;
            font: 11px sans-serif;
            background: lightsteelblue;
            border: 0px;
            border-radius: 4px;
            pointer-events: none;
        }

        .leafletGlyphIcon{
            border:1px solid #555;
            width:100%;
            margin:5px;
        }
        .leafletGlyphIcon:before{
            content:"\e062";
            font-family:"Glyphicons Halflings";
            // line-height:1;
            margin:5px;
            display:inline-block;
        }
    </style>

    <!--
    /*!
     * IE10 viewport hack for Surface/desktop Windows 8 bug
     * Copyright 2014-2015 Twitter, Inc.
     * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
     */

    /*
     * See the Getting Started docs for more information:
     * http://getbootstrap.com/getting-started/#support-ie10-width
     */
    -->
    <style type="text/css">
        @-ms-viewport {
            width: device-width;
        }

        @-o-viewport {
            width: device-width;
        }

        @viewport {
            width: device-width;
        }
    </style>

    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.2.0/dist/leaflet.css"
          integrity="sha512-M2wvCLH6DSRazYeZRIm1JnYyh22purTM+FDB5CsyxtQJYeKq83arPe5wgbNmcFXGqiSH2XR8dT/fJISVA1r/zQ=="
          crossorigin=""/>
    <script src="https://unpkg.com/leaflet@1.2.0/dist/leaflet.js"
            integrity="sha512-lInM/apFSqyy1o6s89K4iQUKg6ppXEgsVxT35HbzUupEVRh2Eu9Wdl4tHj7dZO0s1uvplcYGmt3498TtHq+log=="
            crossorigin=""></script>

    <script type="application/javascript"
            src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.19.1/moment.js"></script>

    <script type="application/javascript"
            src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.19.1/locale/et.js"></script>

    <script src="https://d3js.org/d3.v4.min.js"></script>
    <script>
        moment.locale('et');
        // console.log(moment.locale());

        var now = moment();
        // console.log(now.format());

        var utcnow = moment.utc();
        console.log(utcnow.format());

        var before = moment.utc().subtract(2, 'days');
        // console.log(before.format());

        const sosurl = 'http://ltom-loggernet.domenis.ut.ee:8081/sos/service/json';

        const sosrequest = {
            "request": "GetObservation",
            "service": "SOS",
            "version": "2.0.0",
            "procedure": [
                "temperature-sensor"
            ],
            "offering": [
                "1"
            ],
            "observedProperty": [
                "temperature"
            ],
            "featureOfInterest": [
                "soontaga-station-1"
            ],
            "temporalFilter": [
                {
                    "during": {
                        "ref": "om:phenomenonTime",
                        "value": [
                            before.format(),
                            utcnow.format()
                        ]
                    }
                }
            ]
        };

        // the data
        var obsarray = [];

        var formatTime = d3.timeFormat("%d.%m., %H:%Mh");

        /**
         * On document ready
         */
        $(document).ready(function () {

            var mydiv = d3.select("body").append("div")
                .attr("class", "d3tooltip")
                .attr("id", "mydiv")
                .style("opacity", 0);

            var svg = d3.select("svg"),
                margin = {top: 20, right: 20, bottom: 30, left: 50},
                width = +svg.attr("width") - margin.left - margin.right,
                height = +svg.attr("height") - margin.top - margin.bottom,
                g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

            // 2017-11-07T15:15:28Z
            // 2017-11-07T16:30:00.000Z
            // var parseTimeN52Req = d3.timeParse("%Y-%m-%dT%H:%M:%sZ");
            // var parseTimeN52Obs = d3.timeParse("%Y-%m-%dT%H:%M:%s.%LZ");
            var strictIsoParse = d3.utcParse("%Y-%m-%dT%H:%M:%S.%LZ");

            var parseDate = d3.utcParse("%Y-%m-%dT%H:%M:%S.%LZ"),
                bisectDate = d3.bisector(function (d) {
                    return d.date;
                }).left,
                formatValue = d3.format(",.2f"),
                formatTemp = function (d) {
                    return formatValue(d) + "C";
                };

            var x = d3.scaleTime()
                .rangeRound([0, width]);

            var y = d3.scaleLinear()
                .rangeRound([height, 0]);

            var line = d3.line()
                .x(function (d) {
                    return x(d.date);
                })
                .y(function (d) {
                    return y(d.temp);
                });

            console.log("loading sos data!");

            d3.request(sosurl)
                .header("Content-Type", "application/json")
                .mimeType("application/json")
                .response(function (xhr) {
                    return JSON.parse(xhr.responseText);
                })
                .post(JSON.stringify(sosrequest), function (error, data) {

                    // data.observations.phenomenonTime -> parseTime
                    // data.observations.result.value -> number

                    console.log('loaded ' + data.observations.length + ' observation');

                    jQuery.each(data.observations, function (i, val) {
                        // console.log(JSON.stringify({date: strictIsoParse(val.phenomenonTime), temp: val.result.value}));
                        obsarray.push({date: strictIsoParse(val.phenomenonTime), temp: val.result.value});
                    });


                    if (error) throw error;

                    x.domain(d3.extent(obsarray, function (d) {
                        return d.date;
                    }));
                    y.domain(d3.extent(obsarray, function (d) {
                        return d.temp;
                    }));

                    g.append("g")
                        .attr("transform", "translate(0," + height + ")")
                        .call(d3.axisBottom(x))
                        .select(".domain")
                        .remove();

                    g.append("g")
                        .call(d3.axisLeft(y))
                        .append("text")
                        .attr("fill", "#000")
                        .attr("transform", "rotate(-90)")
                        .attr("y", 6)
                        .attr("dy", "0.81em")
                        .attr("text-anchor", "end")
                        .text("Temperature (C)");

                    var path = g.append("path")
                        .datum(obsarray)
                        .attr("fill", "none")
                        .attr("stroke", "orange")
                        .attr("stroke-linejoin", "round")
                        .attr("stroke-linecap", "round")
                        .attr("stroke-width", 1.5)
                        .attr("d", line);

                    var legendData = [{name: 'Temp in C', color: 'orange'}];

                    var legend = svg.append("g")
                        .data(legendData)
                        .attr('class', 'legend');

                    legend.append('rect')
                        .attr('x', width - 20)
                        .attr('y', function (d, i) {
                            return i * 20;
                        })
                        .attr('width', 10)
                        .attr('height', 10)
                        .style('fill', function (d) {
                            // return color(d.color);
                            return 'orange';
                        });

                    legend.append('text')
                        .attr('x', width - 8)
                        .attr('y', function (d, i) {
                            return (i * 20) + 9;
                        })
                        .text(function (d) {
                            return 'Temperature in &deg;C';
                        });

                    path.on("mouseover", function () {
                        var x0 = x.invert(d3.mouse(this)[0]),
                            i = bisectDate(obsarray, x0, 1),
                            d0 = obsarray[i - 1],
                            d1 = obsarray[i],
                            d = x0 - d0.date > d1.date - x0 ? d1 : d0;

                        var xCoor = d3.mouse(this)[0]; // mouse position in x
                        var yValue = y.invert(xCoor); // value of y axis
                        var xDate = x.invert(xCoor); // date corresponding to mouse x

                        var textStuff = Number(d.temp).toFixed(2) + '&deg;C on ' + formatTime(d.date);

                        // console.log(textStuff);
                        mydiv.transition()
                            .duration(100)
                            .style("opacity", .9);

                        mydiv.html(textStuff)
                            .style("left", (d3.event.pageX) + "px")
                            .style("top", (d3.event.pageY - 50) + "px");
                    })
                        .on("mouseout", function () {
                            mydiv.transition()
                                .duration(500)
                                .style("opacity", 0);
                        });

                });
        });
    </script>

    <meta http-equiv="refresh" content="60">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
    <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
    <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
</head>
<body>

<header>
    <nav class="navbar navbar-inverse navbar-fixed-top">
        <div class="container">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar"
                        aria-expanded="false" aria-controls="navbar">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="navbar-brand" href="#">Soontaga Sensor Station</a>
            </div>
            <div id="navbar" class="collapse navbar-collapse">
                <ul class="nav navbar-nav">
                    <li class="active"><a href="#">Test</a></li>
                    <li><a href="#about">Test</a></li>
                    <li><a href="#contact">Test</a></li>
                </ul>
            </div><!--/.nav-collapse -->
        </div>
    </nav>
</header>

<div class="container-fluid">

    <div class="col-sm-3 col-md-2">
        <div id="map" class="map map-home" style="height: 300px; width: 300px; margin-top: 50px"></div>
    </div>

    <div role="main" class="col-sm-9 col-md-10 starter-template">
        <h2>Soontaga Temperature!</h2>

        <svg width="960" height="500"></svg>

        <p class="lead">Prototype: Demo loading latest 48h temperate data from LoggerNet database via <a
                href="http://www.opengeospatial.org/standards/sos" target="_blank">OGC SOS</a> service standard.<br>
            This is temperature, (half-)hourly averaged at Soontaga. This page reloads itself every 60 seconds.</p>


    </div>

</div><!-- /.container -->

<script type="text/javascript">
    // the map
    var home = {
        lat: 58.00954,
        lng: 26.0866693,
        zoom: 11
    };

    var map = L.map('map').setView([home.lat, home.lng], home.zoom);

    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    L.marker([58.00954, 26.0866693]).addTo(map)
        .bindPopup('Soontaga sensor station.')
        .openPopup();

    var recentreControl = L.Control.extend({

        options: {
            position: 'topleft'
        },

        onAdd: function (map) {
            var container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom leafletGlyphIcon');

            container.title="(Re-)Center map";
            container.style.backgroundColor = 'white';
            container.style.width = '30px';
            container.style.height = '30px';

            // <span class="glyphicon glyphicon-map-marker" aria-hidden="true"></span>
            container.onclick = function(){
                map.setView([home.lat, home.lng], home.zoom);
            };
            return container;
        }

    });

    map.addControl(new recentreControl());
    L.control.scale().addTo(map);
</script>

<!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
<script type="text/javascript">

    /*!
     * IE10 viewport hack for Surface/desktop Windows 8 bug
     * Copyright 2014-2015 Twitter, Inc.
     * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
     */

    // See the Getting Started docs for more information:
    // http://getbootstrap.com/getting-started/#support-ie10-width

    (function () {
        'use strict';

        if (navigator.userAgent.match(/IEMobile\/10\.0/)) {
            var msViewportStyle = document.createElement('style');
            msViewportStyle.appendChild(
                document.createTextNode(
                    '@-ms-viewport{width:auto!important}'
                )
            );
            document.querySelector('head').appendChild(msViewportStyle)
        }

    })();
</script>
</body>
</html>
