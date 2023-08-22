#!/usr/bin/env python3

# Query namespace info

# https://github.com/BrownUniversity/k8s-service-query
# Developed by: thomas_duvally@brown.edu
# 2022-07-25

from os.path import exists as file_exists
import sys
import re
from kubernetes import client, config

html_dir = '/usr/share/nginx/html'
kconfig_dir = '/etc/kubeconfig'
cluster_list = ['qa-bkpd', 'qa-bkpi', 'bkpd', 'bkpi', 'bkpddr', 'bkpidr', 'vo-ranch', 'qvo-ranch', 'scidmz-ranch', 'qscidmz-ranch']
html_start = """
<html>
<head>
<title>Nodes</title>
</head>
<body>
"""

html_end = """
</table>
</html>
"""
def node_list(cl_name):
  # Define Core API connection
  core_query = client.CoreV1Api()
  try:
    node_query = core_query.list_node(watch=False, timeout_seconds=15)
  except:
    print(f'Error in query: {cl_name}')
    return
    
  node_num = len(node_query.items)
  # Setup output file
  output = html_dir + '/' + cl_name + '_nodes.html'
  html_file = open(output, 'w')
  html_file.write(html_start)
  html_file.write('<h1>Cluster ' + cl_name + ' Nodes</h1><table border="1">')
  html_file.write('<tr><th>Node Name</th><th>Node Type</th></tr>\n')
  for node in node_query.items:
    labels = node.metadata.labels
    node_name = labels.get('kubernetes.io/hostname')
    cp_node = labels.get('node-role.kubernetes.io/controlplane', False)
    if cp_node:
      node_text = "ControlPlane"
    else:
      node_text = "Worker"
    html_file.write('<tr><td>' + node_name + '</td><td>' + node_text + '</td></tr>\n')
  html_file.write(html_end)

def main():
  # for each cluster do the thing
  for cl_name in cluster_list:
    # load kconfig yaml
    kconfig_file = kconfig_dir + '/' + cl_name + '.yaml'
    config.load_kube_config(config_file=kconfig_file)
    node_list(cl_name)


## OK, actually do the stuff.
if __name__ == '__main__': main()
