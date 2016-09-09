#!/bin/sh

set -x

nova-manage api_db sync
nova-manage db sync
