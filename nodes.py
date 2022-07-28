#!/usr/bin/env python3

# Query namespace info

# https://github.com/BrownUniversity/k8s-service-query
# Developed by: thomas_duvally@brown.edu
# 2022-07-25

from os.path import exists as file_exists
import sys
import re
from kubernetes import client, config

cluster_list = ['qa-bkpd', 'qa-bkpi', 'bkpd', 'bkpi', 'bkpddr', 'bkpidr', 'vo-ranch', 'qvo-ranch', 'scidmz-ranch']

def node_list(cl_name):
  # Define Core API connection
  core_query = client.CoreV1Api()
  node_query = core_query.list_node(watch=False, timeout_seconds=15)
  node_num = len(node_query.items)
  # Setup output file
  output = 'outputs/' + cl_name + '_nodes.csv'
  csv_file = open(output, 'w')
  csv_file.write('Node,Type\n')
  for node in node_query.items:
    labels = node.metadata.labels
    node_name = labels.get('kubernetes.io/hostname')
    cp_node = labels.get('node-role.kubernetes.io/controlplane', False)
    if cp_node:
      node_text = "ControlPlane"
    else:
      node_text = "Worker"
    csv_file.write(node_name + ', ' + node_text + '\n')

def main():
  # for each cluster do the thing
  for cl_name in cluster_list:
    # load kconfig yaml
    kconfig_file = 'files/' + cl_name + '.yaml'
    config.load_kube_config(config_file=kconfig_file)
    node_list(cl_name)

## OK, actually do the stuff.
if __name__ == '__main__': main()
