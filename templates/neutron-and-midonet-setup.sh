#!/bin/sh

set -x

neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/midonet/midonet.ini upgrade head
neutron-db-manage --subproject networking-midonet upgrade head
