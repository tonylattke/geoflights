angular.module('app.geoflightsApp').controller("HomeCtrl", [ '$scope', ($scope)->

    ################################   Layers  ################################
    
    $scope.total = 0    

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

    vw = new ol.View({
        center: [0,0],
        zoom: 2.75,
        maxZoom: 7,
        minZoom: 2.42
    })
    
    ################################   Map   ##################################

    map = new ol.Map({
        layers: _layers,
        renderer: 'canvas',
        target: 'map',
        view: vw,
        controls: controls
    })

    ###########################################################################

    # A normal select interaction to handle click
    select = new ol.interaction.Select({condition: ol.events.condition.click})
    map.addInteraction(select)

    selected_countries = []

    extent = 1

    map.on('click', 
        (event) ->
            x = event.coordinate[0]
            y = event.coordinate[1]
            testv = 70000
            extent = [x-testv, y-testv, x+testv, y+testv]
            airports_source.forEachFeatureIntersectingExtent(extent, 
                (feature) ->
                    selected_countries.push(feature)
            )
            #console.log(selected_countries)
            selectedFeatures = select.getFeatures()
            console.log(selectedFeatures)
            # selectedFeatures.clear()
    )

    map.on('pointermove', 
        (event) ->
            coord3857 = event.coordinate
            coord4326 = ol.proj.transform(coord3857, 'EPSG:3857', 'EPSG:4326')
            #console.log(coord3857, coord4326)
    )

    ###########################################################################

    $scope.resetCamera = ->
        # Reset zoom
        vw.setZoom(2.75);

        # Reset center
        vw.setCenter([0,0]);
])