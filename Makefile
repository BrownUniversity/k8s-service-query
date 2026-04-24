.DEFAULT_GOAL := help

#help:  @ List available tasks on this project
help:
	@grep -hE '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

## Variables
HASH := $(shell git rev-parse --short HEAD | tr -d '\n')
.PHONY: build dlogin.qa dlogin.prod push.qa push.prod \
	deploy.qa deploy.prod local-check clean

# Include local-dev functions. This includes the secrets creation locally.
include local-dev.mk

## DOCKER BUILD ##
#build: @ Build the docker image, one for all envs
build:
	docker build --load -t harbor.services.brown.edu/bkereporting/reporter:$(HASH) \
	-t harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH) \
	-t harbordr.services.brown.edu/bkereporting/reporter:$(HASH) ./

## DOCKER LOGIN ##
#dlogin.qa: @ QA docker login
dlogin.qa: local-check
	cat secrets/robot-qa.txt | docker login -u 'bke-vo-auto' \
	--password-stdin harbor.cis-qas.brown.edu

#dlogin.dr: @ dr docker login
dlogin.dr: local-check
	cat secrets/robot-dr.txt | docker login -u 'bke-vo-auto' \
	--password-stdin harbordr.services.brown.edu

#dlogin.prod: @ PROD docker login
dlogin.prod: local-check
	cat secrets/robot-prod.txt | docker login -u 'bke-vo-auto' \
	--password-stdin harbor.services.brown.edu

## DOCKER PUSH ##
#push.qa: @ Push image to QA harbor
push.qa: dlogin.qa
	docker push harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH)

#push.dr: @ Push image to dr harbor
push.dr: dlogin.dr
	docker push harbordr.services.brown.edu/bkereporting/reporter:$(HASH)

#push.prod: @ Push image to PROD harbor
push.prod: dlogin.prod
	docker push harbor.services.brown.edu/bkereporting/reporter:$(HASH)

## DELPOY APP TO NAMESPACE ##
#deploy.qa: @ deploy app to QA namespace
deploy.qa: local-check
	kubectl apply -k overlays/qa --kubeconfig=secrets/qa-bkei.yaml
	kubectl set image deployment/bkereporting bkereporting=harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH) -n bkereporting --kubeconfig=secrets/qa-bkei.yaml

#deploy.dr: @ deploy app to dr namespace
deploy.dr: local-check
	kubectl apply -k overlays/dr --kubeconfig=secrets/dr-bkei.yaml
	kubectl set image deployment/bkereporting bkereporting=harbordr.services.brown.edu/bkereporting/reporter:$(HASH) -n bkereporting --kubeconfig=secrets/dr-bkei.yaml


#deploy.prod: @ deploy app to PROD namespace
deploy.prod: local-check
	kubectl apply -k overlays/prod --kubeconfig=secrets/prod-bkei.yaml
	kubectl set image deployment/bkereporting bkereporting=harbor.services.brown.edu/bkereporting/reporter:$(HASH) -n bkereporting --kubeconfig=secrets/prod-bkei.yaml
