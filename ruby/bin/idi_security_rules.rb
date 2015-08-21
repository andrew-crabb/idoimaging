#! /usr/bin/env ruby

require 'aws-sdk'
require 'json'
require 'pp'

REGION_NAME         = 'us-east-1'
PROFILE_NAME        = 'idoimaging'
# SECURITY_GROUP_NAME = 'test1'
SECURITY_GROUP_NAME = 'idoimaging'

Aws.config.update(
  {
    region: REGION_NAME,
    credentials: Aws::SharedCredentials.new(:profile_name => PROFILE_NAME)
  }
)

mypath      = File.expand_path(File.dirname(__FILE__))
config_file = File.read(mypath + '/../../etc/idoimaging_config.json')
config_hash = JSON.parse(config_file)
# puts JSON.pretty_generate(config_hash)

rsrc = Aws::EC2::Resource.new(region: 'us-east-1')

security_group = rsrc.security_groups(group_names: [SECURITY_GROUP_NAME]).first
puts " #{security_group.group_name}  #{security_group.group_id}"

ip_permissions = security_group.ip_permissions
ip_permissions.each do |perm|
  if (perm.from_port == perm.to_port)
    port_no = perm.from_port
  else
    puts "Port range #{perm.from_port} to #{perm.to_port}"
  end
  perm.ip_ranges.each do |range|
    # Delete this permission
    security_group.revoke_ingress({ip_protocol: 'tcp', from_port: perm.from_port, to_port: perm.to_port, cidr_ip: range.cidr_ip.to_s})
    puts "security_group.revoke_egress(ip_protocol: 'tcp', cidr_ip: #{range.cidr_ip}, from_port: #{perm.from_port}, to_port: #{perm.to_port})"
  end
end

config_hash['services'].each do |service|
#  puts service
  port = service['port']
  if service['access'].eql?('public')
    puts "security_group.authorize_ingress(ip_protocol: 'tcp', from_port: #{port}, to_port: #{port}, cidr_ip: '0.0.0.0/0')"
    security_group.authorize_ingress(ip_protocol: 'tcp', from_port: port, to_port: port, cidr_ip: '0.0.0.0/0')
  elsif service['access'].eql?('private')
  	config_hash['ip_numbers'].each do |ip_num|
 # 		puts ip_num
  		cidr_str = ip_num['ip'] + '/' + ip_num['mask']
	    puts "security_group.authorize_ingress(ip_protocol: 'tcp', from_port: #{port}, to_port: #{port}, cidr_ip: #{cidr_str})"
	    security_group.authorize_ingress(ip_protocol: 'tcp', from_port: port, to_port: port, cidr_ip: cidr_str)
  	end
  end
end
