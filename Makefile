#
# Data download and extraction
#

NET_DIR = data/net
NET_SRC = washington-latest.osm.bz2

$(NET_DIR)/washington-latest.osm : $(NET_DIR)/$(NET_SRC)
	bunzip2 -k $(NET_DIR)/$(NET_SRC)
	touch $(NET_DIR)/washington-latest.osm

$(NET_DIR)/$(NET_SRC) $(NET_DIR)/$(NET_SRC).sha256.valid :
	mkdir -p $(NET_DIR)
	curl -o $(NET_DIR)/$(NET_SRC) \
	http://download.geofabrik.de/north-america/us/$(NET_SRC)

	[ `echo $(NET_DIR)/$(NET_SRC).sha256` == `sha256 $(NET_DIR)/$(NET_SRC)`]: \
		echo 1 > $(NET_DIR)/$(NET_SRC).sha256.valid
