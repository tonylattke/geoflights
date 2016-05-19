angular.module('app.geoflightsApp').controller("ConnectionsCtrl", [ '$scope', '$http', ($scope,$http)->

    $scope.current_coordinate = {
        longitude: 0,
        latitude: 0
    }

    $scope.airport = {
        id: 0
        name: ''
        latitude: 0
        longitude: 0
    }
    
    $scope.route = ''

    ################################    Init   ################################

    $scope.init = (route, airport_id, airport_name, airport_longitude, airport_latitude) ->
        $scope.route = route

        $scope.airport = {
            id: airport_id
            name: airport_name
            latitude: parseFloat(airport_latitude)
            longitude: parseFloat(airport_longitude)
        }

        ################################   Layers  ################################

        # Countries

        countries_source = new ol.source.TileWMS({
            url: 'http://localhost:8080/geoserver/kss/wms',
            params: {
                'LAYERS': 'kss:countries'
            }
        })

        countries_layer = new ol.layer.Tile({
            source:  countries_source
        })

        # Airports

        layer_connection = ''
        if $scope.route == 'destiny'
            layer_connection = 'kss:select_destiny_airports'
        else
            layer_connection = 'kss:select_source_airports'

        airports_source = new ol.source.TileWMS({
            url: 'http://localhost:8080/geoserver/kss/wms' + '?viewparams=S_AIRPORT_ID:' + $scope.airport.id
            params: {
                'LAYERS': layer_connection
            }
        })

        airports_layer = new ol.layer.Tile({
            source:  airports_source
        })

        # Arcs

        arcsVector = new ol.source.Vector()

        arcs_map_layer = new ol.layer.Vector({
            source: arcsVector
            style: new ol.style.Style()
        })
        
        airport_layer = drawAirport()

        # Main layers list

        _layers = [
            countries_layer,
            airports_layer,
            arcs_map_layer,
            airport_layer
        ]

        ################################ Controls #################################

        controls = new ol.control.defaults({
            zoom: false,
            attribution: false
        })

        ################################   View   #################################

        view = new ol.View({
            center: [0,0],
            zoom: 2.75,
            maxZoom: 7,
            minZoom: 2.42
        })
        
        ################################   Map   ##################################

        $scope.map = new ol.Map({
            layers: _layers,
            renderer: 'canvas',
            target: 'map',
            view: view,
            controls: controls
        })

        ###########################################################################
        
        $scope.map.on('pointermove', 
            (event) ->
                coord3857 = event.coordinate
                coord4326 = ol.proj.transform(coord3857, 'EPSG:3857', 'EPSG:4326')
                $scope.current_coordinate = {
                    longitude: coord4326[0],
                    latitude: coord4326[1]
                }
                $scope.$apply();
        )

        layer_connection = 'kss:'
        if $scope.route == 'destiny'
            layer_connection += 'select_destiny_airports'
        else
            layer_connection += 'select_source_airports'


        request = "http://localhost:8080/geoserver/kss/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=" + layer_connection + "&viewparams=S_AIRPORT_ID:" + $scope.airport.id + "&outputFormat=application%2Fjson"
        $http({
            method: 'GET'
            url: request
        }).then(
            (answer) ->
                
                airports_raw = answer['data']['features']
                
                len = answer['data']['features'].length
                i = 0                
                while i < len
                    airport_aux = {
                        id: airports_raw[i]['properties']['airport_id']
                        name: airports_raw[i]['properties']['name']
                        longitude: parseFloat(airports_raw[i]['properties']['longitude'])
                        latitude: parseFloat(airports_raw[i]['properties']['latitude'])
                    }
                    pointA = projectCoord([$scope.airport['longitude'], $scope.airport['latitude']])
                    pointB = projectCoord([airport_aux['longitude'], airport_aux['latitude']])
                    
                    arcFeature = createArcBetweenPoints(pointA, pointB)
                    arcsVector.addFeature(arcFeature)
                
                    i += 1
                
        )

    ###########################################################################

    $scope.selectAirport = ->
        window.location.href = "/home"

    $scope.selectCountry = ->
        window.location.href = "/countries"

    ###########################################################################

    bounce = (t) ->
        s = 7.5625
        p = 2.75
        l = 0
        
        if t < (1 / p)
            l = s * t * t
        else
            if t < (2 / p)
                t -= (1.5 / p)
                l = s * t * t + 0.75
            else
                if (t < (2.5 / p))
                    t -= (2.25 / p)
                    l = s * t * t + 0.9375
                else
                    t -= (2.625 / p)
                    l = s * t * t + 0.984375            
        
        return l

    elastic = (t) ->
        return Math.pow(2, -10 * t) * Math.sin((t - 0.075) * (2 * Math.PI) / 0.3) + 1

    $scope.resetCamera = ->
        duration = 2000;
        start = +new Date();
        pan = ol.animation.pan({
            duration: duration,
            source: view.getCenter(),
            start: start
        })
        bounce = ol.animation.bounce({
            duration: duration,
            resolution: 2*view.getResolution(),
            start: start
        })
        $scope.map.beforeRender(pan,bounce)
        
        view.setCenter([0,0])

    $scope.resetZoom = ->
        # Reset zoom
        view.setZoom(2.75)

    projectCoord = (coordinate) ->
      coord = ol.proj.transform(coordinate, 'EPSG:4326', 'EPSG:3857')
      point = new ol.geom.Point(coord)
      return point

    createArcBetweenPoints = (pointA, pointB) ->
        transformedA = pointA.transform('EPSG:3857', 'EPSG:4326')
        transformedB = pointB.transform('EPSG:3857', 'EPSG:4326')
        start = {
            x: transformedA.getCoordinates()[0]
            y: transformedA.getCoordinates()[1]
        }
        end = {
            x: transformedB.getCoordinates()[0]
            y: transformedB.getCoordinates()[1]
        }
        generator = new arc.GreatCircle(start, end, {
            'name': ''
        })
        line = generator.Arc(100, {
            offset: 10
        })
        coordinates = line.geometries[0].coords
        lineString = new ol.geom.LineString(coordinates)
        geom = lineString.transform('EPSG:4326', 'EPSG:3857')
        feature = new ol.Feature({
            'geometry': geom
        })

        # Adds an arrow
        lineStyles = [
            new ol.style.Style({
                stroke: new ol.style.Stroke({
                    color: '#00FFFC'
                    width: 2
                })
            })
        ]

        feature.setStyle(lineStyles)

        return feature

    drawAirport = ->
        iconStyle = new ol.style.Style({
 
          image: new ol.style.Circle({
              radius: 10
              fill: new ol.style.Fill({
                  color: '#00FFFC'
              }),
              stroke: new ol.style.Stroke({
                  color: '#FFFFFF'
                  width: 3
              })
          })
          zIndex: 1
            
        })

        icons = []
        lon = $scope.airport.longitude
        lat = $scope.airport.latitude
        iconFeature = new ol.Feature(
            { 
                geometry: projectCoord([lon, lat])
            })
        #aaa = new ol.geom.Point(ol.proj.transform([lon, lat], 'EPSG:4326', 'EPSG:3857'))        
        iconFeature.setStyle(iconStyle)
        icons.push(iconFeature)
        pointLayer = new ol.layer.Vector({ 
            source: new ol.source.Vector(
                { 
                    features: icons 
                }) 
        })

        return pointLayer

    #$scope.$apply();
])