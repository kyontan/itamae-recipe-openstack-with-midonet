#!/bin/sh

set -x

keystone-manage db_sync
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
