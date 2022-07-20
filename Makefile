.DEFAULT_GOAL := help

#help:  @ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

CLUSTERS ?= qa-bkpd qa-bkpi bkpd bkpi bkpddr bkpidr vo-ranch qvo-ranch scidmz-ranch
GREPOUT ?= 'cattle|kube|nfs|ingress-nginx|sumologic|fleet|local'

#secrets: @ Files to decrypt
SECRET_FILES=$(shell cat .blackbox/blackbox-files.txt)
$(SECRET_FILES): %: %.gpg
	gpg --decrypt --quiet --no-tty --yes $< > $@

.PHONY: 

yamls: files/qa-bkpi.yaml files/qa-bkpd.yaml files/bkpi.yaml files/bkpd.yaml files/bkpidr.yaml files/bkpddr.yaml files/qvo-ranch.yaml files/scidmz-ranch.yaml files/vo-ranch.yaml

## Namespaces
#namespaces: @ namespaces info by CLUSTER var
namespaces: yamls
	@$(foreach file, $(CLUSTERS), echo "####### $(file) NAMESPACES ######" ; kubectl get namespaces -A -o=custom-columns=NAME:.metadata.name,OWNER:.metadata.labels.owner --kubeconfig=files/$(file).yaml| grep -Ev $(GREPOUT) ; echo "" ;)

## Deployments
#deployments: @ deployment info by CLUSTERS var
deployments: yamls
	@$(foreach file, $(CLUSTERS), echo "####### $(file) DEPLOYMENTS ######" ; kubectl get deployments -A -o=custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace --kubeconfig=files/$(file).yaml| grep -Ev $(GREPOUT) ; echo "" ;)

#cronjobs: @ cronjob info by CLUSTERS var
cronjobs: yamls
	@$(foreach file, $(CLUSTERS), echo "####### $(file) CRONJOBS ######" ;kubectl get cronjobs -A -o=custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace --kubeconfig=files/$(file).yaml| grep -Ev $(GREPOUT) ; echo ""; )

#nodes: @ List nodes for CLUSTERS var
nodes: yamls
	@$(foreach file, $(CLUSTERS), echo "###### $(file) NODES ######" ; kubectl get nodes --kubeconfig=files/$(file).yaml ; echo "" ;)

#used: @ Is the namespace being used
used: yamls
	$(foreach file, $(CLUSTERS), echo "###### $(file) USED NS ######" ; for M in $(shell kubectl get namespace --no-headers -o=custom-columns=NAME:.metadata.name --kubeconfig=files/$(file).yaml |grep -Ev "security-scan|default|cattle|kube|nfs|ingress-nginx|sumologic|fleet|local|oit|ccvressys"); do echo -n $$M,; kubectl get all -n $$M --no-headers --ignore-not-found --kubeconfig=files/$(file).yaml| wc -l | xargs test 0 -lt && echo "true" || echo "false";done)

#list: @ list cluster names
list:
	@$(foreach file, $(CLUSTERS), echo "\t$(file)";)
