.DEFAULT_GOAL := help

#help:  @ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#secrets: @ Files to decrypt
SECRET_FILES=$(shell cat .blackbox/blackbox-files.txt)
$(SECRET_FILES): %: %.gpg
	gpg --decrypt --quiet --no-tty --yes $< > $@

.PHONY: 

yamls: secrets/qa-bkpi.yaml secrets/qa-bkpd.yaml secrets/bkpi.yaml secrets/bkpd.yaml secrets/bkpidr.yaml secrets/bkpddr.yaml secrets/qvo-ranch.yaml secrets/scidmz-ranch.yaml secrets/vo-ranch.yaml

#secrets: @ publish secrets to namespace
secrets: yamls
	echo "secrets"

#deploy: @ deploy app to namespace
deploy: secrets
	echo "deploy"

