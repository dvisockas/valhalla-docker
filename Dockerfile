FROM valhalla/valhalla:run-3.1.3

RUN apt update
RUN apt-get -y install wget


COPY ./valhalla-config.json .
COPY ./tile-links.txt .

# Download tiles
# TODO: Check sha of file and invalidate layer if changed
RUN for i in $(cat tile-links.txt); do wget $i; done

RUN apt-get -y install python3-distutils python3-apt

RUN mkdir -p valhalla_tiles
RUN valhalla_build_config --mjolnir-tile-dir ${PWD}/valhalla_tiles --mjolnir-tile-extract ${PWD}/valhalla_tiles.tar --mjolnir-timezone ${PWD}/valhalla_tiles/timezones.sqlite --mjolnir-admin ${PWD}/valhalla_tiles/admins.sqlite > valhalla.json
# Build timezones.sqlite to support time-dependent routing
RUN valhalla_build_timezones > valhalla_tiles/timezones.sqlite
# Build routing tiles
RUN ls *.osm.pbf | xargs valhalla_build_tiles -c valhalla.json
# RUN valhalla_build_extract -c valhalla.json -v
RUN find valhalla_tiles | sort -n | tar cf valhalla_tiles.tar --no-recursion -T -

WORKDIR /tiles
CMD valhalla_service ../valhalla.json $(nproc)
