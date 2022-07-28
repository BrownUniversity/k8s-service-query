#!/usr/bin/env python3

# Query namespace info

# https://github.com/BrownUniversity/k8s-service-query
# Developed by: thomas_duvally@brown.edu
# 2022-07-20

from os.path import exists as file_exists
import sys
import re
from kubernetes import client, config


html_dir = '/usr/share/nginx/html'
cluster_list = ['qa-bkpd', 'qa-bkpi', 'bkpd', 'bkpi', 'bkpddr', 'bkpidr', 'vo-ranch', 'qvo-ranch', 'scidmz-ranch']
excluded_raw = [
  'security-scan',
  'default',
  'ingress-nginx',
  'local',
  'cattle*',
  'fleet*',
  'kube*',
  'oitbusint',
  'oiteas',
  'oiteas-mybrown',
  'oitwebservices',
  'oitccv',
  'oitvo',
  'oitresrequest',
  'compsci',
  'ccvressys',
  'backup'
]
temp = '(?:% s)' % '|'.join(excluded_raw)

# Define the function that does the thing 
def nsquery(cl_name):
  # Define Core API connection
  core_query = client.CoreV1Api()
  # Setup output file
  output = html_dir + 'outputs/' + cl_name + '_namespaces.csv'
  csv_file = open(output, 'w')
  csv_file.write('Namespace, Owner, Resources\n')
  # Get namespace list
  namespace_info = core_query.list_namespace(watch=False, timeout_seconds=15)
  # Get namespace list but remove some (system, utility, etc)
  for ns in namespace_info.items:
    if re.match(temp, ns.metadata.name):
      pass
    else :
      # Get labels, but handle missing ones
      labels = ns.metadata.labels
      if (type(labels) == dict):
        ns_owner = labels.get("owner")
        if ns_owner:
          pass
        else:
          ns_owner = "oitvo"
        # Output info
        ns_resources = res_count(ns.metadata.name)
        csv_file.write(ns.metadata.name + ', ' + ns_owner + ', ' + str(ns_resources) + '\n')

# Get count of various resources in a namespace
def res_count(namespace):
  res_num = 0
  # Define all the API connections
  core_query = client.CoreV1Api()
  app_query = client.AppsV1Api()
  job_query = client.BatchV1Api()
  cron_query = client.BatchV1beta1Api()
  # Pull in other resources for this namespace
  pods_info = core_query.list_namespaced_pod(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(pods_info.items)
  service_info = core_query.list_namespaced_service(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(service_info.items)
  deploy_info = app_query.list_namespaced_deployment(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(deploy_info.items)
  daemon_info = app_query.list_namespaced_daemon_set(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(daemon_info.items)
  stateful_info = app_query.list_namespaced_stateful_set(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(stateful_info.items)
  replica_info = app_query.list_namespaced_replica_set(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(replica_info.items)
  job_info = job_query.list_namespaced_job(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(job_info.items)
  cron_info = cron_query.list_namespaced_cron_job(namespace, watch=False, timeout_seconds=15)
  res_num = res_num + len(cron_info.items)
  return res_num

# define the for loop that iterates over the the cluster lists 
def main():
  # for each cluster do the thing
  for cl_name in cluster_list:
    # load kconfig yaml 
    kconfig_file = 'files/' + cl_name + '.yaml'
    config.load_kube_config(config_file=kconfig_file)
    nsquery(cl_name)

## OK, actually do the stuff.
if __name__ == '__main__': main()