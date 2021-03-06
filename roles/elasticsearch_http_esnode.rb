name        "elasticsearch_http_esnode"
description "[Infochimps internal] HTTP esnode for elasticsearch cluster."

# List of recipes and roles to apply
run_list(*%w[
  cluster_chef::dedicated_server_tuning
  elasticsearch::autoconf
  elasticsearch::default
  elasticsearch::install_from_release
  elasticsearch::install_plugins
  nginx::prepare_for_source
  nginx::source
  elasticsearch::http
])
