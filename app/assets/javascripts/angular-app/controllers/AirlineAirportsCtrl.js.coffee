angular.module('app.geoflightsApp').controller("AirlineAirportsCtrl", [ '$scope', ($scope)->

    $scope.current_coordinate = {
        longitude: 0,
        latitude: 0
    }

    $scope.airline = {
        id: 0
        name: ''
    }

    ################################    Init   ################################

    $scope.init = (airline_id, airline_name) ->

        $scope.airline = {
            id: airline_id
            name: airline_name
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

        airports_source = new ol.source.TileWMS({
            url: 'http://localhost:8080/geoserver/kss/wms' + '?viewparams=AIRLINE_ID:' + $scope.airline.id
            params: {
                'LAYERS': 'kss:select_airlne_airports'
            }
        })

        airports_layer = new ol.layer.Tile({
            source:  airports_source
        })        

        # Main layers list

        _layers = [
            countries_layer,
            airports_layer
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

    #$scope.$apply();
])