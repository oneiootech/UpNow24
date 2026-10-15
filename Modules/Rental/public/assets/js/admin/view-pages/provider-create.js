"use strict";

let map = null;
let zonePolygon = null;
let infoWindow = null;
let bounds = null;
let markers = [];

$('#pac-input1').on('keydown', function(event) {
    if (event.key === 'Enter') {
        event.preventDefault();
    }
});

function updateZone(id) {
    if (!id) return;
    let urlTemplate = $('#choice_zones').data('zone-coordinates-url');
    if (!urlTemplate) return;
    let url = urlTemplate.replace('PLACEHOLDER_ID', id);

    $.get({
        url: url,
        dataType: 'json',
        success: function(data) {
            if (!map || typeof google === 'undefined' || !google.maps) return;
            if (zonePolygon) {
                zonePolygon.setMap(null);
            }
            zonePolygon = new google.maps.Polygon({
                paths: data.coordinates,
                strokeColor: "#FF0000",
                strokeOpacity: 0.8,
                strokeWeight: 2,
                fillColor: 'white',
                fillOpacity: 0,
            });
            zonePolygon.setMap(map);

            let zoneBounds = new google.maps.LatLngBounds();
            zonePolygon.getPaths().forEach(function(path) {
                path.forEach(function(latlng) {
                    zoneBounds.extend(latlng);
                });
            });

            map.fitBounds(zoneBounds);

            map.addListener('idle', function() {
                const customZoom = 15;
                if (map.getZoom() > customZoom) {
                    map.setZoom(customZoom);
                }
            });

            google.maps.event.addListener(zonePolygon, 'click', function(mapsMouseEvent) {
                if (infoWindow) infoWindow.close();
                infoWindow = new google.maps.InfoWindow({
                    position: mapsMouseEvent.latLng,
                    content: JSON.stringify(mapsMouseEvent.latLng.toJSON(), null, 2),
                });

                let coordinates = mapsMouseEvent.latLng.toJSON();
                let latEl = document.getElementById('latitude');
                let lngEl = document.getElementById('longitude');
                if (latEl) latEl.value = coordinates.lat;
                if (lngEl) lngEl.value = coordinates.lng;
                infoWindow.open(map);
            });
        },
    });
}

function initMap() {
    let mapElement = document.getElementById("map");
    if (!mapElement) return;

    if (typeof google === 'undefined' || !google.maps) {
        console.warn("Google Maps API is not loaded yet.");
        return;
    }

    let storeLat = parseFloat($('#data-set').data('lat')) || 23.757989;
    let storeLng = parseFloat($('#data-set').data('lng')) || 90.360587;
    let myLatlng = { lat: storeLat, lng: storeLng };

    map = new google.maps.Map(mapElement, {
        zoom: 13,
        center: myLatlng,
    });

    infoWindow = new google.maps.InfoWindow({
        content: "Click the map to get Lat/Lng!",
        position: myLatlng,
    });

    bounds = new google.maps.LatLngBounds();

    const input = document.getElementById("pac-input1");
    if (input) {
        const searchBox = new google.maps.places.SearchBox(input);
        map.controls[google.maps.ControlPosition.TOP_CENTER].push(input);

        searchBox.addListener("places_changed", () => {
            const places = searchBox.getPlaces();
            if (!places || places.length === 0) return;

            markers.forEach((marker) => marker.setMap(null));
            markers = [];

            const placeBounds = new google.maps.LatLngBounds();
            places.forEach((place) => {
                if (!place.geometry || !place.geometry.location) return;

                let latEl = document.getElementById('latitude');
                let lngEl = document.getElementById('longitude');
                if (latEl) latEl.value = place.geometry.location.lat();
                if (lngEl) lngEl.value = place.geometry.location.lng();

                const icon = {
                    url: place.icon,
                    size: new google.maps.Size(71, 71),
                    origin: new google.maps.Point(0, 0),
                    anchor: new google.maps.Point(17, 34),
                    scaledSize: new google.maps.Size(25, 25),
                };

                markers.push(
                    new google.maps.Marker({
                        map: map,
                        icon: icon,
                        title: place.name,
                        position: place.geometry.location,
                    })
                );

                if (place.geometry.viewport) {
                    placeBounds.union(place.geometry.viewport);
                } else {
                    placeBounds.extend(place.geometry.location);
                }
            });
            map.fitBounds(placeBounds);
        });
    }

    google.maps.event.addListener(map, 'click', function(mapsMouseEvent) {
        if (infoWindow) infoWindow.close();
        let coords = mapsMouseEvent.latLng.toJSON();
        infoWindow = new google.maps.InfoWindow({
            position: mapsMouseEvent.latLng,
            content: JSON.stringify(coords, null, 2),
        });

        let latEl = document.getElementById('latitude');
        let lngEl = document.getElementById('longitude');
        if (latEl) latEl.value = coords.lat;
        if (lngEl) lngEl.value = coords.lng;
        infoWindow.open(map);
    });

    let currentZoneId = $('#choice_zones').val();
    if (currentZoneId) {
        updateZone(currentZoneId);
    }
}
window.initMap = initMap;

$(document).ready(function() {
    $('.offcanvas').on('click', function() {
        $('.offcanvas, .floating--date').removeClass('active')
    })
    $('.floating-date-toggler').on('click', function() {
        $('.offcanvas, .floating--date').toggleClass('active')
    })

    let admin_zone_id = $('#data-set').data('admin-zone-id');
    if (admin_zone_id) {
        $('#choice_zones').trigger('change');
    }

    if (typeof google !== 'undefined' && google.maps && !map) {
        initMap();
    }
});

function readURL(input, viewer) {
    if (input.files && input.files[0]) {
        let reader = new FileReader();
        reader.onload = function(e) {
            $('#' + viewer).attr('src', e.target.result);
        }
        reader.readAsDataURL(input.files[0]);
    }
}

$('#choice_zones').on('change', function() {
    let id = $(this).val();
    updateZone(id);
});

$("#vendor_form").on('keydown', function(e) {
    if (e.keyCode === 13) {
        e.preventDefault();
    }
})

$('#reset_btn').click(function() {
    $('#logoImageViewer').attr('src', $('#data-set').data('logoImageViewer'));
    $('#customFileEg1').val(null);
    $('#coverImageViewer').attr('src', $('#data-set').data('logoImageViewer'));
    $('#coverImageUpload').val(null);
    $('#choice_zones').val(null).trigger('change');
    $(".multiple-select2").val(null).trigger("change");
    $('#module_id').val(null).trigger('change');
    if (zonePolygon) zonePolygon.setMap(null);
    $('#coordinates').val(null);
    $('#latitude').val(null);
    $('#longitude').val(null);
})

let zone_id = 0;
$('#choice_zones').on('change', function() {
    if ($(this).val()) {
        zone_id = $(this).val();
    }
});

$('#module_id').select2({
    ajax: {
        url: $('#data-set').data('get-all-modules-url'),
        data: function(params) {
            return {
                q: params.term,
                page: params.page,
                zone_id: zone_id
            };
        },
        processResults: function(data) {
            return {
                results: data
            };
        },
        __port: function(params, success, failure) {
            let $request = $.ajax(params);
            $request.then(success);
            $request.fail(failure);
            return $request;
        }
    }
});

$('.delivery-time').on('click', function() {
    let min = $("#minimum_delivery_time").val();
    let max = $("#maximum_delivery_time").val();
    let type = $("#delivery_time_type").val();
    $("#floating--date").removeClass('active');
    $("#time_view").val(min + ' to ' + max + ' ' + type);
});
