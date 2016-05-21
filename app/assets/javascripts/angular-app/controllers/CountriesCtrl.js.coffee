angular.module('app.geoflightsApp').controller("CountriesCtrl", [ '$scope', '$http', ($scope,$http)->

    $scope.selected_country = {
        status: false
        name: ''
        airlines:[]
    }
    $scope.current_coordinate = {
        longitude: 0,
        latitude: 0
    }

    $scope.selected_airline = {
        countries:[]
        airline: {
            id: 0
            name: ''
            selected: false
        }
    }
    
    ################################   Layers  ################################

    # Countries

    countries_source = new ol.source.Vector({
        #url: 'http://openlayers.org/en/v3.15.1/examples/data/geojson/countries.geojson'
        #url: 'countries.geojson'
        url: 'http://localhost:8080/geoserver/kss/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=kss:countries&outputFormat=application%2Fjson'
        format: new ol.format.GeoJSON()
    })

    countries_styles = [
        new ol.style.Style({
              stroke: new ol.style.Stroke({
                color: '#00FFFC',
                width: 1
              }),
              fill: new ol.style.Fill({
                color: '#004241'
              })
          })
    ]

    countries_styles_selected = new ol.style.Style({
        stroke: new ol.style.Stroke({
            color: '#00FFFC',
            width: 3
        })
        fill: new ol.style.Fill({
            color: '#007574'
        })
    })

    countries_layer = new ol.layer.Vector({
        source: countries_source
        style: countries_styles
    })

    # Main layers list

    _layers = [
        countries_layer
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
        maxZoom: 9,
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
    select = new ol.interaction.Select(
        {
            condition: ol.events.condition.click
            layers: 
                (layer) ->
                    return layer.get('selectable') == true
            style: [countries_styles_selected]
        })
    countries_layer.set('selectable', true);
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
            countries_source.forEachFeatureIntersectingExtent(extent, 
                (feature) ->
                    selected_countries.push(feature)
            )
            
            if selected_countries.length > 0

                $scope.selected_country = {
                    status: true
                    name: selected_countries[0]['U']['NAME']
                    airlines:[]
                }

                request = "http://localhost:8080/geoserver/kss/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=kss:select_country_airlines" + "&viewparams=COUNTRY_NAME:" + $scope.selected_country['name'] + "&outputFormat=application%2Fjson"
                
                $http({
                    method: 'GET'
                    url: request
                }).then(
                    (answer) ->
                        airlines_raw = answer['data']['features']
                        
                        airlines = []
                        
                        len = answer['data']['features'].length
                        i = 0
                        while i < len
                            airline = {
                                id: airlines_raw[i]['properties']['airline_id']
                                name: airlines_raw[i]['properties']['name']
                                selected: false
                            }
                            airlines.push(airline)
                            i += 1

                        $scope.selected_country.airlines = airlines

                        $scope.selected_airline = {
                            countries:[]
                            airline: {
                                id: 0
                                name: ''
                                selected: false
                            }
                        }
                )
            else
                $scope.selected_country = {
                    status: false
                    name: ''
                    airlines:[]
                }
                $scope.selected_airline = {
                    countries:[]
                    airline: {
                        id: 0
                        name: ''
                        selected: false
                    }
                }

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

    selectCountriesOnMap = ->
        select.getFeatures().clear()
        countries_source.forEachFeature(
            (country_feature) ->
                len = $scope.selected_airline['countries'].length
                i = 0
                while i < len
                    if country_feature.get('NAME') is $scope.selected_airline['countries'][i]['name']
                        select.getFeatures().push(country_feature)
                    i += 1
        )

    $scope.selectAirline = (airline) ->
        $scope.selected_airline['airline']['selected'] = false
        airline['selected'] = true

        request = "http://localhost:8080/geoserver/kss/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=kss:select_airline_countries" + "&viewparams=AIRLINE_ID:" + airline['id'] + "&outputFormat=application%2Fjson"
        $http({
            method: 'GET'
            url: request
        }).then(
            (answer) ->
                airline['selected'] = true
                $scope.selected_airline['airline'] = airline

                countries_raw = answer['data']['features']
                
                countries = []
                
                len = answer['data']['features'].length
                i = 0
                while i < len
                    country = {
                        name: countries_raw[i]['properties']['country']
                    }
                    countries.push(country)
                    i += 1

                $scope.selected_airline['countries'] = countries

                #selectCountriesOnMap()
        )

    ###########################################################################

    $scope.selectAirport = ->
        window.location.href = "/home"

    $scope.selectCountry = ->
        window.location.href = "/countries"

    $scope.showAirline = ->
        window.location.href = "/airline/" + $scope.selected_airline['airline']['id'] + "/" + $scope.selected_airline['airline']['name']

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