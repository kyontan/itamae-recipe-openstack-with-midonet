# OpenStack Mitaka + Midonet Provisioning Scripts

## Requires

1. 2 hosts installed CentOS 7 (controller node / compute node)
1. Ruby 2.x + Itamae gem (required only in provisioner host)

## Usage

### First time

1. Edit `hosts`
1. Run `./node_json_generate`

`./itamae-runner all recipes/[script].rb`

if you want to provision specified host:

`./itamae-runner [hostname] recipes/[script].rb`

## Scripts (sorted for running)

1. update-hosts.rb
1. setup-midonet-repositories.rb
1. set-selinux-permissive.rb
1. install-chrony.rb
1. install-openstack-packages.rb
1. install-mariadb.rb
1. install-mongodb.rb
1. install-rabbitmq.rb
1. install-memcached.rb
1. install-openstack-keystone.rb
1. setup-accounts.rb
1. setup-midonet-to-keystone.rb
1. install-openstack-glance.rb
1. install-openstack-nova-controller.rb
1. install-openstack-nova-compute.rb
1. setup-midonet-to-nova.rb
1. install-openstack-neutron-with-midonet-controller.rb
1. install-openstack-neutron-with-midonet-compute.rb
