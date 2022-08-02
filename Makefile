.DEFAULT_GOAL := help

#help:  @ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#secrets: @ Files to decrypt
SECRET_FILES=$(shell cat .blackbox/blackbox-files.txt)
$(SECRET_FILES): %: %.gpg
	gpg --decrypt --quiet --no-tty --yes $< > $@

## Variables
HASH := $(shell git rev-parse --short HEAD | tr -d '\n')
CLUSTER ?= bkpd bkpi bkpddr bkpidr qa-bkpd qa-bkpi vo-ranch qvo-ranch scidmz-ranch

.PHONY: build dlogin.qa dlogin.prod push.qa push.prod \
	secrets.qa secrets.prod deploy.qa deploy.prod

yamls: secrets/qa-bkpi.yaml secrets/qa-bkpd.yaml secrets/bkpi.yaml \
	secrets/bkpd.yaml secrets/bkpidr.yaml secrets/bkpddr.yaml \
	secrets/qvo-ranch.yaml secrets/scidmz-ranch.yaml secrets/vo-ranch.yaml

## DOCKER BUILD ##
#build: @ Build the docker image, one for all envs
build:
	docker build -t harbor.services.brown.edu/bkereporting/reporter:$(HASH) \
	-t harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH) ./

## DOCKER LOGIN ##
#dlogin.qa: @ QA docker login
dlogin.qa: secrets/robot.qa
	cat secrets/robot.qa | docker login -u 'bke-bkereporting+build' \
	--password-stdin harbor.cis-qas.brown.edu

#dlogin.prod: @ PROD docker login
dlogin.prod: secrets/robot.prod
	cat secrets/robot.prod | docker login -u 'bke-bkereporting+build' \
	--password-stdin harbor.services.brown.edu

## DOCKER PUSH ##
#push.qa: @ Push image to QA harbor
push.qa: dlogin.qa
	docker push harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH)

#push.prod: @ Push image to PROD harbor
push.prod: dlogin.prod
	docker push harbor.services.brown.edu/bkereporting/reporter:$(HASH)

## CREATE/UPDATE SECRETS TO NAMESPACE ##
#secrets.qa: @ publish secrets to QA namespace
secrets.qa: yamls
	$(foreach CL_NAME, $(CLUSTER), \
	kubectl delete secret $(CL_NAME) --ignore-not-found -n bkereporting --kubeconfig=secrets/qa-bkpi.yaml; \
	kubectl create secret generic $(CL_NAME) --from-file=secrets/$(CL_NAME).yaml \
	-n bkereporting --kubeconfig=secrets/qa-bkpi.yaml ; )

#secrets.prod: @ publish secrets to PROD namespace
secrets.prod: yamls
	$(foreach CL_NAME, $(CLUSTER), \
	kubectl delete secret $(CL_NAME) --ignore-not-found -n bkereporting --kubeconfig=secrets/bkpi.yaml; \
	kubectl create secret generic $(CL_NAME) --from-file=secrets/$(CL_NAME).yaml \
	-n bkereporting --kubeconfig=secrets/bkpi.yaml ; )

## DELPOY APP TO NAMESPACE ##
#deploy.qa: @ deploy app to QA namespace
deploy.qa: secrets.qa
	kubectl apply -k overlays/qa --kubeconfig=secrets/qa-bkpi.yaml
	kubectl set image deployment/bkereporting harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH)

#deploy.prod: @ deploy app to PROD namespace
deploy.prod: secrets.prod
	kubectl apply -k overlays/prod --kubeconfig=secrets/bkpi.yaml
	kubectl set image deployment/bkereporting harbor.services.brown.edu/bkereporting/reporter:$(HASH)
