# Chef Client Config File
# Automatically grabs configuration from ohai ec2 metadata.

require 'ohai'
require 'json'

o = Ohai::System.new
o.all_plugins

log_level            :info
log_location         STDOUT
validation_key       "/etc/chef/validation.pem"
client_key           "/etc/chef/client.pem"
CLIENT_CONFIG_FILE = "/etc/chef/client-config.json"
file_cache_path      "/srv/chef/cache"
pid_file             "/var/run/chef/chef-client.pid"
ssl_verify_mode      :verify_none
Mixlib::Log::Formatter.show_time = true

def node_launch_index
  o[:ec2][:ami_launch_index]
end

# if the node_name is given, use that;
# if the cluster name, cluster role (and optional index) are given, use "cluster-role-index"
# otherwise, use the instance_id.
def get_node_name
  case
  when chef_config["node_name"]
    chef_config["node_name"]
  when chef_config["cluster_name"] && chef_config["cluster_role"]
    [chef_config["cluster_name"], chef_config["cluster_name"], node_launch_index].compact.join('-')
  else
    o[:ec2][:instance_id]
  end
end

user_data          = o[:ec2][:userdata]
chef_config = JSON.parse(user_data) rescue nil
if ! chef_config.nil?  # Yays we got user-data to config with

  # If it's an array, assume it's for a robot army of similar machines, and
  # extract the setup accordingly.
  if chef_config.kind_of?(Array)
    chef_config = chef_config[node_launch_index]
  end

  # How to identify node to chef server.
  chef_server_url        chef_config["chef_server"]
  validation_client_name chef_config["validation_client_name"]
  node_name get_node_name

  # If the client file is missing, write the validation key out so chef-client
  # can register
  if File.exists?("/etc/chef/client.pem")
    # File.rm(validation_key)
  else
    File.open(validation_key, "w", 0600) do |f|
      f.print(chef_config["validation_key"])
    end
  end

  # Adopt chef config settings from the attributes key
  if chef_config.has_key?("attributes") && (not File.exists?(CLIENT_CONFIG_FILE))
    File.open(CLIENT_CONFIG_FILE, "w") do |f|
      f.print(JSON.pretty_generate(chef_config["attributes"]))
    end
  end
else # no user-data ACK!
  chef_server_url        "http://chef.infinitemonkeys.info:4000"
  validation_client_name "chef-validator"
  node_name              o[:ec2][:instance_id]
end

json_attribs CLIENT_CONFIG_FILE if File.exists?(CLIENT_CONFIG_FILE)