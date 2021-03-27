#
# Map Making
#

geo2topo = node_modules/.bin/geo2topo
shp2json = node_modules/.bin/shp2json

geo2topo: $(geo2topo)
shp2json: $(shp2json)

$(geo2topo) $(shp2json): package.json
	yarn install
	touch -c \
		$(geo2topo) \
		$(shp2json) \
		 || exit 1

maps: maps/sfshore.json \
			maps/tahoe.json \
			maps/belvedere.json \
			maps/coast_potomac.json \
			maps/coast_catalina.json \
			maps/ny_shoreline.json \
			maps/gibraltar.json \
			maps/goga_tracts.json \
			maps/english_channel.json \
			maps/bayarea_general.json \
			maps/bayarea_bridges.json \
			maps/seattle.json \
			maps/ocean_bay.json \
			maps/north_channel.json

maps/%.json: _maps/%.json
	cp $< $@

clean:
	rm -rf maps/* _maps/*

.DEFAULT_GOAL := maps

#
# sfshore: The San Francisco shoreline
#

_maps/sfshore.zip:
	curl -L "https://data.sfgov.org/api/geospatial/rgcx-5tix?method=export&format=Shapefile" > $@

_maps/sfshore/: _maps/sfshore.zip
	unzip -n $< -d $@

_maps/sfshore_geojson.json: _maps/sfshore/ | $(shp2json)
	$(shp2json) `ls $</*.shp | head -n 1` > $@

_maps/sfshore.json: _maps/sfshore_geojson.json | $(geo2topo)
	$(geo2topo) --out $@ -- sfshore=$<


# https://data.sfgov.org/Geographic-Locations-and-Boundaries/Bay-Area-General/g59h-rxxm
_maps/bayarea_general.zip:
	curl -L "https://data.sfgov.org/api/geospatial/g59h-rxxm?method=export&format=Shapefile" > $@

_maps/bayarea_general/: _maps/bayarea_general.zip
	unzip -n $< -d _maps/bayarea_general/
	touch -c _maps/bayarea_general/* || exit 1

# geojson
_maps/bayarea_general_geojson.json: _maps/bayarea_general/ | $(shp2json)
	$(shp2json) `ls _maps/bayarea_general/*.shp | head -n 1` > $@

# remove some cruft
_maps/bayarea_general_geojson_lite.json: _maps/bayarea_general_geojson.json
	./scripts/geojson-select objectid=1 objectid=2 < $< > $@

_maps/bayarea_general.json: _maps/bayarea_general_geojson_lite.json | $(geo2topo)
	$(geo2topo) --out $@ -- bayarea_general=$<

# bayarea bridges
_maps/bayarea_bridges.zip:
	curl -L http://spatial.lib.berkeley.edu/public/ark28722-s7ng6f/data.zip > $@

_maps/bayarea_bridges/bayarea_bridges.shp \
_maps/bayarea_bridges/bayarea_bridges.dbf: _maps/bayarea_bridges.zip
	unzip -n $< -d _maps/bayarea_bridges/
	touch -c _maps/bayarea_bridges/* || exit 1

_maps/bayarea_bridges_geojson.json: _maps/bayarea_bridges/bayarea_bridges.shp _maps/bayarea_bridges/bayarea_bridges.dbf | $(shp2json)
	$(shp2json) $< > $@

_maps/bayarea_bridges.json: _maps/bayarea_bridges_geojson.json | $(geo2topo)
	$(geo2topo) --out $@ -- bayarea_bridges=$<

_maps/goga_tracts/GOGA_tracts.shp \
_maps/goga_tracts/GOGA_tracts.dbf: _src/goga_tracts.zip
	unzip -n $< -d `dirname $@`
	touch -c `dirname $@`/* || exit 1

_maps/goga_tracts_geojson.json: _maps/goga_tracts/GOGA_tracts.shp _maps/goga_tracts/GOGA_tracts.dbf | $(shp2json)
	$(shp2json) $< > $@

_maps/goga_tracts.json: _maps/goga_tracts_geojson.json | $(geo2topo)
	$(geo2topo) --out $@ -- goga_tracts=$<

# no idea where this waterbodies dataset came from :[
_maps/tahoe.json: _src/tahoe.json
	mkdir -p _maps
	cp $< $@

_maps/marin/waterbody.zip:
	mkdir -p _maps/marin
	curl -L http://www.marinmap.org/PublicRecords/data/VectorData/MarinCounty/waterbody.zip > _maps/marin/waterbody.zip

_maps/marin/waterbody/waterbody.shp \
_maps/marin/waterbody/waterbody.dbf: _maps/marin/waterbody.zip
	unzip $< -d _maps/marin/waterbody/
	touch -c _maps/marin/waterbody/* || exit 1

_maps/marin/waterbody.json: _maps/marin/waterbody/waterbody.shp _maps/marin/waterbody/waterbody.dbf | $(shp2json)
	$(shp2json) $< > $@

# just belvedere lagoon
_maps/marin/belvedere_geojson.json: _maps/marin/waterbody.json
	./scripts/geojson-select "Name=BELVEDERE LAGOON" < $< > $@

# geo2topo
_maps/belvedere.json: _maps/marin/belvedere_geojson.json
	$(geo2topo) --out $@ -- belvedere=$<

# this link is broken now, or at least gets very cranky without a referer
# http://www.marinmap.org/PublicRecords/_maps/Vector_maps/MarinCounty/ocean_bay.zip
_maps/ocean_bay.json: _src/ocean_bay.json
	cp $< $@

# geojson
_maps/coast/coast.json: _src/coast.shp _src/coast.dbf | $(shp2json)
	mkdir -p _maps/coast
	$(shp2json) $< > $@

# just catalina and coast
_maps/coast/coast_catalina_geojson.json: _maps/coast/coast.json
	./scripts/geojson-select COASTLN010={262,263,264,265,269,270,271,273,1158} < $< > $@

# geo2topo
_maps/coast_catalina.json: _maps/coast/coast_catalina_geojson.json | $(geo2topo)
	$(geo2topo) --out $@ -- coast_catalina=$<

# just the potomac river/chesapeake bay
_maps/coast/coast_potomac_geojson.json: _maps/coast/coast.json
	./scripts/geojson-select \
		COASTLN010={1874,1381,1388,1389,1391,1385,1383,1379,1382,1378,1371,1370,1369,1368,1366,1358,1357,1356} \
		< $< > $@

# geo2topo
_maps/coast_potomac.json: _maps/coast/coast_potomac_geojson.json | $(geo2topo)
	$(geo2topo) --out $@ -- coast_potomac=$<

# nyc outline
_maps/coast/coast_nyc_geojson.json: _maps/coast/coast.json
	./scripts/geojson-select \
		COASTLN010={113,1874,122,121,120,119,970,102,87,108,86,88,101,97} \
		< $< > $@

# geo2topo
_maps/coast_nyc.json: _maps/coast/coast_nyc_geojson.json | $(geo2topo)
	$(geo2topo) --out $@ -- coast_nyc=$<

# NYC shoreline
# https://data.cityofnewyork.us/Recreation/Shoreline/2qj2-cctx/data
_maps/ny_shoreline/ny_shoreline_geojson.json:
	mkdir -p `dirname $@`
	curl "https://data.cityofnewyork.us/api/geospatial/2qj2-cctx?method=export&format=GeoJSON" > $@

# geo2topo
_maps/ny_shoreline.json: _maps/ny_shoreline/ny_shoreline_geojson.json | $(geo2topo)
	$(geo2topo) --out $@ -- ny_shoreline=$<

# http://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-coastline/
_maps/coastline/ne_10m_coastline.zip:
	mkdir -p `dirname $@`
	curl -L http://naciscdn.org/naturalearth/10m/physical/ne_10m_coastline.zip > $@

_maps/coastline/ne_10m_coastline/ne_10m_coastline.shp \
_maps/coastline/ne_10m_coastline/ne_10m_coastline.dbf: _maps/coastline/ne_10m_coastline.zip
	unzip -n _maps/coastline/ne_10m_coastline.zip -d _maps/coastline/ne_10m_coastline/
	touch -c _maps/coastline/ne_10m_coastline/* || exit 1

_maps/coastline/ne_10m_coastline_gibraltar_geojson.json: _maps/coastline/ne_10m_coastline/ne_10m_coastline.shp _maps/coastline/ne_10m_coastline/ne_10m_coastline.dbf
	# ogr2ogr -f GeoJSON -t_srs wgs84 -clipsrc -11 -31 1 40	$@ $<
	$(shp2json) $< > $@

_maps/coastline/gibraltar.json: _maps/coastline/ne_10m_coastline_gibraltar_geojson.json
	$(geo2topo) --out $@ -- gibraltar=$<

_maps/coastline/ne_10m_coastline_english_channel_geojson.json: _maps/coastline/ne_10m_coastline _maps/coastline/ne_10m_coastline/ne_10m_coastline.shp _maps/coastline/ne_10m_coastline/ne_10m_coastline.dbf
	# ogr2ogr -f GeoJSON -t_srs wgs84 -clipsrc 0 49 4 53	$@ $<
	$(shp2json) $< > $@

_maps/coastline/english_channel.json: _maps/coastline/ne_10m_coastline_english_channel_geojson.json
	$(geo2topo) --out $@ -- english_channel=$<

_maps/coastline/ne_10m_seattle_geojson.json: _maps/coastline/ne_10m_coastline/ne_10m_coastline.shp _maps/coastline/ne_10m_coastline/ne_10m_coastline.dbf
	# ogr2ogr -f GeoJSON -t_srs wgs84 -clipsrc -129 51 -120 46	$@ $<
	$(shp2json) $< > $@

_maps/seattle.json: _maps/coastline/ne_10m_seattle_geojson.json
	$(geo2topo) --out $@ -- seattle=$<

_maps/europe_coastline/europe_coastline.zip:
	mkdir -p `dirname $@`
	# curl -L https://www.eea.europa.eu/data-and-maps/_maps/eea-coastline-for-analysis-1/gis-_maps/europe-coastline-shapefile/at_download/file > $@
	curl -L https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-2/gis-data/eea-coastline-polyline/at_download/file > $@

_maps/europe_coastline/europe_coastline/%: _maps/europe_coastline/europe_coastline.zip
	mkdir -p `dirname $@`
	unzip -n $< -d `dirname $@`
	touch -c `dirname $@`/* || exit 1

europe_poly_file = Europe_coastline_raw_rev2017

_maps/europe_coastline/english_channel_geojson.json: _maps/europe_coastline/europe_coastline/$(europe_poly_file).shp _maps/europe_coastline/europe_coastline/$(europe_poly_file).dbf | $(shp2json)
	# ogr2ogr -f GeoJSON -t_srs wgs84 -clipsrc 3365311 2914999 3981932 3283361 $@ $<
	$(shp2json) $< > $@

_maps/english_channel.json: _maps/europe_coastline/english_channel_geojson.json
	$(geo2topo) --out $@ -- english_channel=$<

_maps/europe_coastline/gibralatar_geojson.json: _maps/europe_coastline/europe_coastline/$(europe_poly_file).shp _maps/europe_coastline/europe_coastline/$(europe_poly_file).dbf | $(shp2json)
	# ogr2ogr -f GeoJSON -t_srs wgs84 -clipsrc 2502286 1356092 3251273 1791719 $@ $<
	$(shp2json) $< > $@

_maps/gibraltar.json: _maps/europe_coastline/gibralatar_geojson.json
	$(geo2topo) --out $@ -- gibraltar=$<

_maps/europe_coastline/north_channel_geojson.json: _maps/europe_coastline/europe_coastline/$(europe_poly_file).shp _maps/europe_coastline/europe_coastline/$(europe_poly_file).dbf | $(shp2json)
	# ogr2ogr -f GeoJSON -t_srs wgs84 -clipsrc 3218493 3719794 3510336 3525232 $@ $<
	$(shp2json) $< > $@

_maps/north_channel.json: _maps/europe_coastline/north_channel_geojson.json
	$(geo2topo) --out $@ -- north_channel=$<
