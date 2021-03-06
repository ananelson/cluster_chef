name        "elasticsearch_data_esnode"
description "[Infochimps internal] Data esnode (holds and indexes data) for elasticsearch cluster."

# List of recipes and roles to apply
run_list(*%w[
  cluster_chef::dedicated_server_tuning
  elasticsearch::autoconf
  elasticsearch::default
  elasticsearch::install_from_release
  elasticsearch::install_plugins
  elasticsearch::server
  elasticsearch::http
])
