.DEFAULT_GOAL := help

#help:  @ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

CLUSTERS ?= qa-bkpd qa-bkpi bkpd bkpi bkpddr bkpidr vo-ranch qvo-ranch scidmz-ranch
GREPOUT ?= 'oit|cattle|kube|nfs|cert-manager|sumologic|fleet-agent'

#secrets: @ Files to decrypt
SECRET_FILES=$(shell cat .blackbox/blackbox-files.txt)
$(SECRET_FILES): %: %.gpg
	gpg --decrypt --quiet --no-tty --yes $< > $@

.PHONY: 

yamls: files/qa-bkpi.yaml files/qa-bkpd.yaml files/bkpi.yaml files/bkpd.yaml files/bkpidr.yaml files/bkpddr.yaml files/qvo-ranch.yaml files/scidmz-ranch.yaml files/vo-ranch.yaml

## Deployments
#deployments: @ deployment info by CLUSTERS var
deployments: yamls
	@$(foreach file, $(CLUSTERS), echo "####### $(file) DEPLOYMENTS ######" ; kubectl get deployments -A -o=custom-columns=NAME:.metadata.name,Namespace:.metadata.namespace --kubeconfig=files/$(file).yaml| grep -Ev $(GREPOUT) ; echo "" ;)

#cronjobs: @ cronjob info by CLUSTERS var
cronjobs: yamls
	@$(foreach file, $(CLUSTERS), echo "####### $(file) CRONJOBS ######" ;kubectl get cronjobs -A -o=custom-columns=NAME:.metadata.name,Namespace:.metadata.namespace --kubeconfig=files/$(file).yaml| grep -Ev $(GREPOUT) ; echo ""; )

#report: @ report on all clusters
report: files/qa-bkpi.yaml files/qa-bkpd.yaml files/bkpi.yaml files/bkpd.yaml files/bkpidr.yaml files/bkpddr.yaml
	@$(foreach file, $(CLUSTERS), kubectl get nodes --kubeconfig=files/$(file).yaml| grep Ready | wc -l ; )