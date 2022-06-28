# K8S Service Query

This is a set of files and commands to query the Rancher/BKE services

## Requirements

* gnu Makefile
* kubectl
* blackbox

## Basic

Make has build in help. Just run `make`.

All clusters are reported by default, but can be selected using the CLUSTERS 
variable.

For example, this will only list cronjobs for the PROD VO cluster and PROD DMZ 
BKE cluster:

```
# make cronjobs CLUSTERS="vo-ranch bkpd"
```