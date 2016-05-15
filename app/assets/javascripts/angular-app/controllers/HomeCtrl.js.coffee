angular.module('app.geoflightsApp').controller("HomeCtrl", [ '$scope', ($scope)->

    $scope.selected_airport = {
        status: false
        id: 0
        name: ''
        country: ''
        latitude: 0
        longitude: 0
    }
    $scope.current_coordinate = {
        longitude: 0,
        latitude: 0
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

    airports_source = new ol.source.Vector({
        #url: 'http://openlayers.org/en/v3.15.1/examples/data/geojson/countries.geojson',
        url: 'airports.json',
        format: new ol.format.GeoJSON()
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

    airports_layer = new ol.layer.Vector({
        source: airports_source,
        style: airports_styles
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

    # A normal select interaction to handle click
    select = new ol.interaction.Select({condition: ol.events.condition.click})
    $scope.map.addInteraction(select)

    selected_countries = []

    extent = 1

    $scope.map.on('click', 
        (event) ->
            selected_countries = []

            x = event.coordinate[0]
            y = event.coordinate[1]
            testv = 70000
            extent = [x-testv, y-testv, x+testv, y+testv]
            airports_source.forEachFeatureIntersectingExtent(extent, 
                (feature) ->
                    selected_countries.push(feature)
            )
            
            if selected_countries.length > 0
                console.log(selected_countries[0])
                $scope.selected_airport = {
                    status: true
                    id: selected_countries[0].get('airport_id'),
                    name: selected_countries[0].get('name'),
                    country: selected_countries[0].get('country')
                    latitude: selected_countries[0].get('latitude')
                    longitude: selected_countries[0].get('longitude')
                }
            else
                $scope.selected_airport = {
                    status: false
                    id: 0
                    name: ''
                    country: ''
                    latitude: 0
                    longitude: 0
                }

            # selectedFeatures = select.getFeatures()
            # console.log(selectedFeatures)
            # selectedFeatures.clear()

            $scope.$apply();
    )

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
    $scope.showAirlines = (country) ->
        alert(country)

    $scope.showDestinations = (airport_id) ->
        window.location.href = "/connections_airports/destiny/" + $scope.selected_airport.id + "/" + $scope.selected_airport.name + "/" + $scope.selected_airport.latitude + "/" + $scope.selected_airport.longitude

    $scope.showOrigins = (airport_id) ->
        alert(airport_id)

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

])