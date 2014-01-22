# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
class @Map
  constructor: (@selector, when_ready_func = null) ->
    L.Icon.Default.imagePath = '/images';
    
    @map = L.map(@selector, {
    }).setView([64.8595627003585, -147.84934364372472], 4)
    
    @map.addLayer(Gina.Layers.get('TILE.EPSG:3857.BDL'), true)

    baseLayers = {
      'GINA\'s Best Data Layer': Gina.Layers.get('TILE.EPSG:3857.BDL'),
      'USGS Topographic DRG': Gina.Layers.get('TILE.EPSG:3857.TOPO'),
      'NOAA Nautical Charts DRG': Gina.Layers.get('TILE.EPSG:3857.CHARTS'),
      'GINA Shaded Relief (NED)': Gina.Layers.get('TILE.EPSG:3857.SHADED_RELIEF'),
      'Panchromatic Landsat': Gina.Layers.get('TILE.EPSG:3857.LANDSAT_PAN')
    }

    overlays = []
    @layers_control = L.control.layers(baseLayers, overlays, {
      autoZIndex: false,
      collapsed: false
    }).addTo(@map);

    
    @map.whenReady(when_ready_func, @) if when_ready_func? 
  
  # delegate these to the map class, eventually we will add additional stuff to handle base layers
  hasLayer: (layer) =>
    @map.hasLayer(layer)
  
  removeLayer: (layer) =>
    @map.removeLayer(layer)
  
  addLayer: (layer, name, base = false) =>
    @map.addLayer(layer, base)
    layer.bringToFront()
    
  addOverlay: (layer, name) =>
    @map.addLayer(layer)
    
  clearMarkers: =>
    if @request?
      @request.abort();
      
    @markers.clearLayers();
  
  fromPagedAPI: (url) =>
    @progress = new Progress("#progress-container", 'loading sites...')    
    
    @request = @fromAPI(url)
    @request.done (response, text, xhr) => 
      links = {
        next_page: xhr.getResponseHeader('X-Next-Link'),
        offset: parseInt(xhr.getResponseHeader('X-Page')),
        total: parseInt(xhr.getResponseHeader('X-Total-Pages'))
      }
      # links = {}
      
      if links.next_page? and links.next_page != ''
        @progress.update(parseInt(links.offset / links.total * 100))
        @fromPagedAPI(links.next_page) 
      else
        @finishRequest()
        
    @request.fail @finishRequest
      
  finishRequest: =>
    @progress.done()      
      
  fromAPI: (url, clustered = true) =>
    $.getJSON url, (geojson) => 
      @fromGeoJSON(geojson, clustered)
  
  fromGeoJSON: (geojson, clustered = true) =>
    geojson_layer = L.geoJson(geojson, {
      onEachFeature: (feature, layer) =>
        layer.bindPopup(@description(feature));
    })
    
    if clustered
      @add2ClusteredMarkersLayer(geojson_layer)
    else
      @map.addLayer(geojson_layer)
      geojson_layer.on('click', @markerClick)
      
    
    # this is needed to handle issue with zooming to soon after initialization
    # setTimeout(=> 
    #   @map.fitBounds(@markers.getBounds())
    # , 100)
  
  add2ClusteredMarkersLayer: (layer) =>
    unless @markers?
      @markers = new L.MarkerClusterGroup()
      @map.addLayer(@markers)
      @markers.on('click', @markerClick)
        
    @markers.addLayer(layer)
    
  fromWKT: (wkt, fit = true) =>
    reader = new Wkt.Wkt();
    reader.read(wkt)
    object = reader.toObject()
    object.addTo(@map)
    if fit
      # this is needed to handle issue with zooming to soon after initialization
      setTimeout =>
        @map.fitBounds(object.getBounds(), { animate: true })
      , 100
      
  geojsonMarkerOptions: ->
    {
      radius: 8,
      fillColor: "#ff7800",
      color: "#000",
      weight: 1,
      opacity: 1,
      fillOpacity: 0.6
    }
      
  description: (feature) ->
    output = "<fieldset class='site-marker-popup'><legend>#{feature.properties.sitename}</legend>"
    output +=  "<label>Location: </label> (#{feature.geometry.coordinates[1]}, #{feature.geometry.coordinates[0]})<br/>
                <label>Elevation:</label> #{feature.geometry.coordinates[2]} (M)<br/>"
    output +=  "<label>Comments: </label> #{feature.properties.comments}<br/>" if feature.properties.comments?
    output += "</fieldset>"
    
    output
