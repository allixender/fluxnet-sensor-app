<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->

    <script src="https://cdn.polyfill.io/v2/polyfill.min.js"></script>

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

        .leafletGlyphIcon {
            border: 1px solid #555;
            width: 100%;
            margin: 5px;
        }

        .leafletGlyphIcon:before {
            content: "\e062";
            font-family: "Glyphicons Halflings";
        / / line-height: 1;
            margin: 5px;
            display: inline-block;
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

    <script src="https://d3js.org/d3.v4.min.js"></script>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <!-- For Geochart and Map Chart, you must load both the old library loader and the new library loader.
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    -->
    <script type="text/javascript">

        var now = moment();
        // console.log(now.format());

        var utcnow = moment.utc();
        console.log(utcnow.format());

        var before = moment.utc().subtract(2, 'days');
        // console.log(before.format());

        // var strictIsoParse = d3.utcParse("%Y-%m-%dT%H:%M:%S.%LZ");
        function strictIsoParse(dateString) {
            // console.log(JSON.stringify(moment.utc(dateString)));
            return moment.utc(dateString).toDate();
        }

        function roundSignal2 (numValue) {
            return Math.round(numValue * 100) / 100;
        }

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

        // Load the Visualization API and the corechart package.
        google.charts.load('current', {'packages': ['corechart'], 'language': 'en'});

        // Set a callback to run when the Google Visualization API is loaded.
        google.charts.setOnLoadCallback(drawChart);

        // Callback that creates and populates a data table,
        // instantiates the pie chart, passes in the data and
        // draws it.
        function drawChart() {
            // Create the data table.
            $.ajax({
                type: 'POST',
                url: sosurl,
                data: JSON.stringify(sosrequest),
                contentType: 'application/json',
                dataType: 'json',
                success: function (data) {
                    // the data
                    var obsarray = [['Time', 'Temperature']];

                    // data.observations.phenomenonTime -> parseTime
                    // data.observations.result.value -> number

                    console.log('loaded ' + data.observations.length + ' observation');
                    // console.log(JSON.stringify(data.observations));

                    jQuery.each(data.observations, function (i, val) {
                        // console.log(JSON.stringify([strictIsoParse(val.phenomenonTime), val.result.value]));
                        obsarray.push([strictIsoParse(val.phenomenonTime), roundSignal2(val.result.value)]);
                    });

                    var tableData = google.visualization.arrayToDataTable(obsarray);

                    var options = {
                        // title: 'Soontaga Temperature',
                        hAxis: {
                            title: 'Time'
                        },
                        vAxis: {
                            title: 'Temperature'
                        },
                        colors: ['#AB0D06'],
                        trendlines: {
                            0: {type: 'exponential', color: '#333', opacity: .5}
                        }
                    };

                    var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
                    chart.draw(tableData, options);

                    // var csv = google.visualization.dataTableToCsv(tableData);
                    // console.log(csv);
                }
            });
        }
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
                    <li class="active"><a href="#">Temperature</a></li>
                </ul>
            </div><!--/.nav-collapse -->
        </div>
    </nav>
</header>

<div class="container-fluid">

    <div class="row">
        <div class="col-lg-3 col-md-4 col-sm-6">
            <div id="map" class="map map-home" style="height: 300px; width: 300px; margin-top: 50px"></div>
        </div>

        <div role="main" class="col-lg-9 col-md-10 col-sm-12 starter-template">
            <!-- <h2>Soontaga Temperature</h2> -->

            <!--Div that will hold the  chart-->
            <div id="chart_div"></div>

            <p class="lead">Prototype: Demo loading latest 48h temperate data from LoggerNet database via <a
                    href="http://www.opengeospatial.org/standards/sos" target="_blank">OGC SOS</a> service standard.<br>
                This is temperature, (half-)hourly averaged at Soontaga. This page reloads itself every 60 seconds.</p>


        </div>
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

            container.title = "(Re-)Center map";
            container.style.backgroundColor = 'white';
            container.style.width = '30px';
            container.style.height = '30px';

            // <span class="glyphicon glyphicon-map-marker" aria-hidden="true"></span>
            container.onclick = function () {
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
