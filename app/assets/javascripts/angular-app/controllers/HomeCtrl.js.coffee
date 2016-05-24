angular.module('app.geoflightsApp').controller("HomeCtrl", [ '$scope', ($scope)->

    $scope.access = ->
        window.location.href = "/airports"

])