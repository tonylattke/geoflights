angular.module('app.geoflightsApp').controller("ConnectionsCtrl", [ '$scope', ($scope)->

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

    $scope.init = (route, airport_id, airport_name, airport_latitude, airport_longitude) ->
        $scope.route = route

        $scope.airport = {
            id: airport_id
            name: airport_name
            latitude: airport_latitude
            longitude: airport_longitude
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


        airports_styles = [
            new ol.style.Style({
                image: new ol.style.Circle({
                  radius: 3,
                  stroke: new ol.style.Stroke({
                    color: 'white',
                    width: 1
                  }),
                  fill: new ol.style.Fill({
                    color: '#00FFFC'
                  })
                })
              })
        ]

        ### test ###
        lineLayer = drawRoutes()

        ### test ###
        
        pointLayer = drawAirport()

        # Main layers list

        _layers = [
            countries_layer,
            #lineLayer,
            airports_layer,
            #pointLayer
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


    ###########################################################################

        

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

    drawRoutes = ->
        coords = [[-65.65, 10.10], [0, 0]]
        lineString = new ol.geom.LineString(coords)

        lineString.transform('EPSG:4326', 'EPSG:3857')

        # create the feature
        feature = new ol.Feature({
            geometry: lineString
            name: 'Line'
        })

        lineStyle = new ol.style.Style({
            stroke: new ol.style.Stroke({
                color: '#00FFFC'
                width: 5
            })
        })

        source = new ol.source.Vector({
            features: [feature]
        })
        vector = new ol.layer.Vector({
            source: source
            style: [lineStyle]
        })

        return vector

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
                geometry: new ol.geom.Point(ol.proj.transform([lon, lat], 'EPSG:3857', 'EPSG:4326'))
            })
        aaa = new ol.geom.Point(ol.proj.transform([lon, lat], 'EPSG:4326', 'EPSG:3857'))        
        console.log(aaa)
        iconFeature.setStyle(iconStyle)
        icons.push(iconFeature)
        pointLayer = new ol.layer.Vector({ 
            source: new ol.source.Vector(
                { 
                    features: icons 
                }) 
        })

])