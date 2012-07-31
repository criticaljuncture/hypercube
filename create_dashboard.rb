require 'yaml'
require 'erb'
require 'json'

def contruct_cube_metric_query(metric, fqdn)
  #cube.metric("max(collectd(memory).eq(host,'" + fqdn + "').eq(type, 'inactive'))")

  #query = ['cube.metric("']
  query = ["#{metric['expression']}(#{metric['query']}.eq(host,'#{fqdn}')"]
  if metric['type']
    query << ".eq(type,'#{metric['type']}')"
  end
  query << ')'

  query.join('')
end

def contruct_cube_metric_id(metric, fqdn)
  fqdn.gsub('.', '-') + '-' + metric['id']
end

metric_config = YAML.load_file( File.join('config', 'metrics.yml'))['metrics']
server_groups = YAML.load_file( File.join('config', 'metrics.yml'))['servers']

metrics_for_all = server_groups['all']['metrics'].to_a

server_html = []
metric_queries = []
server_groups.each do |group_name, value|
  next if group_name == 'all'
  
  group_metrics = value['metrics'] + metrics_for_all
  hosts = value['hosts']

  
  group_metrics.each do |group_metric|
    hosts.each do |host|
      metric_queries << [ 
                          contruct_cube_metric_query(metric_config[group_metric], host),
                          contruct_cube_metric_id(metric_config[group_metric], host),
                          group_name,
                          metric_config[group_metric]['label']
                        ]
    end
  end
  
  group_partial = File.read( File.join('templates', 'server_group.html.erb') )
  server_html << ERB.new(group_partial).result(binding)
end

server_hosts = {}
server_groups.each{|name, value| next if name == 'all'; server_hosts[name] = value['hosts'] }

cubism_template =  File.read( File.join('templates', 'javascripts', 'cubism.html.erb') )
cubism = ERB.new(cubism_template).result(binding)

cubism_server_template = File.read( File.join('templates', 'javascripts', 'servers.html.erb') )
cubism_servers = ERB.new(cubism_server_template).result(binding)

dashboard_template = File.read( File.join('templates', 'layouts', 'dashboard.html.erb') )
dashboard = ERB.new(dashboard_template).result(binding)

File.open('test.html', 'w') do |f|
  f.puts dashboard
end