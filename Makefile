.DEFAULT_GOAL := help

#help:  @ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#secrets: @ Files to decrypt
SECRET_FILES=$(shell cat .blackbox/blackbox-files.txt)
$(SECRET_FILES): %: %.gpg
	gpg --decrypt --quiet --no-tty --yes $< > $@

.PHONY: 

yamls: files/qa-bkpi.yaml files/qa-bkpd.yaml files/bkpi.yaml files/bkpd.yaml files/bkpidr.yaml files/bkpddr.yaml files/qvo-ranch.yaml files/scidmz-ranch.yaml files/vo-ranch.yaml

#namespaces: @ namespaces info by CLUSTER
namespaces: yamls
	./namespace.py

#nodes: @ Node info by cluster
nodes: yamls
	./nodes.py

#export: @ Move exported files 
export: 
