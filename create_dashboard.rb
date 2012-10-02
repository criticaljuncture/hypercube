require 'rubygems'
require 'yaml'
require 'erb'
require 'json'

def contruct_cube_metric_query(metric, fqdn)
  #cube.metric("max(collectd(memory).eq(host,'" + fqdn + "').eq(type, 'inactive'))")

  #query = ['cube.metric("']
  query = ["#{metric['expression']}(#{metric['query']}.eq(host,'#{fqdn}')"]

  if metric['params']
    metric['params'].each do |param|
      query << ".eq(#{param[0]},'#{param[1]}')"
    end
  end
  query << ')'

  query.join('')
end

def contruct_cube_metric_id(name, fqdn)
  fqdn.gsub('.', '-') + '-' + name.gsub('_', '-')
end

metric_config = YAML.load_file( File.join('config', 'metrics.yml'))['metrics']
server_groups = YAML.load_file( File.join('config', 'servers.yml'))[:servers]

metrics_for_all = server_groups.select{|sg| sg[:name] == 'all'}[0][:metrics]

server_html = []
metric_queries = []
server_groups.each do |server_group|
  next if server_group[:name] == 'all'
 
  group_name = server_group[:name]
  group_metrics = server_group[:metrics] + metrics_for_all
  hosts = server_group[:hosts]

  group_metrics.each do |metric|
    hosts.each do |host|
      metric_queries << [ 
                          contruct_cube_metric_query(metric_config[metric], host),
                          contruct_cube_metric_id(metric, host),
                          group_name,
                          metric_config[metric]['label'],
                          host.gsub('-','_').gsub('.','_') + "_" + metric,
                        ]
    end
  end
  
  group_partial = File.read( File.join('templates', 'server_group.html.erb') )
  server_html << ERB.new(group_partial).result(binding)
end

server_hosts = {}
server_groups.each do |server_group|
  next if server_group[:name] == 'all'
  server_hosts[server_group[:name]] = server_group[:hosts]
end


cubism_template =  File.read( File.join('templates', 'javascripts', 'cubism.html.erb') )
cubism = ERB.new(cubism_template).result(binding)

cubism_server_template = File.read( File.join('templates', 'javascripts', 'servers.html.erb') )
cubism_servers = ERB.new(cubism_server_template).result(binding)

dashboard_template = File.read( File.join('templates', 'layouts', 'dashboard.html.erb') )
dashboard = ERB.new(dashboard_template).result(binding)

File.open('dashboard.html', 'w') do |f|
  f.puts dashboard
end
