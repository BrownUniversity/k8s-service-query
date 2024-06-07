.DEFAULT_GOAL := help

#help:  @ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

## Variables
HASH := $(shell git rev-parse --short HEAD | tr -d '\n')
CLUSTER ?= prod-bkpd prod-bkpi dr-bkpd dr-bkpi qa-bkpd qa-bkpi prod-voutil prod-voranch qa-voranch prod-scidmz qa-scidmz

.PHONY: build dlogin.qa dlogin.prod push.qa push.prod \
	secrets.qa secrets.prod deploy.qa deploy.prod

#local-dev: @ pull in secrets from bke-vo-secrets repo
local-dev:
	git clone git@github.com:BrownUniversity/bke-vo-secrets.git 
	cd bke-vo-secrets && make secrets
	mkdir secrets
	cp ./bke-vo-secrets/kubeconf/*.yaml ./secrets
	cp ./bke-vo-secrets/robot/*.txt ./secrets

## DOCKER BUILD ##
#build: @ Build the docker image, one for all envs
build:
	docker build -t harbor.services.brown.edu/bkereporting/reporter:$(HASH) \
	-t harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH) ./

## DOCKER LOGIN ##
#dlogin.qa: @ QA docker login
dlogin.qa:
	cat secrets/robot.qa | docker login -u 'bke-vo-auto' \
	--password-stdin harbor.cis-qas.brown.edu

#dlogin.prod: @ PROD docker login
dlogin.prod: 
	cat secrets/robot.prod | docker login -u 'bke-vo-auto' \
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
secrets.qa:
	$(foreach CL_NAME, $(CLUSTER), \
	kubectl delete secret $(CL_NAME) --ignore-not-found -n bkereporting --kubeconfig=secrets/qa-bkpi.yaml; \
	kubectl create secret generic $(CL_NAME) --from-file=secrets/$(CL_NAME).yaml \
	-n bkereporting --kubeconfig=secrets/qa-bkpi.yaml ; )

#secrets.prod: @ publish secrets to PROD namespace
secrets.prod:
	$(foreach CL_NAME, $(CLUSTER), \
	kubectl delete secret $(CL_NAME) --ignore-not-found -n bkereporting --kubeconfig=secrets/prod-bkpi.yaml; \
	kubectl create secret generic $(CL_NAME) --from-file=secrets/$(CL_NAME).yaml \
	-n bkereporting --kubeconfig=secrets/prod-bkpi.yaml ; )

## DELPOY APP TO NAMESPACE ##
#deploy.qa: @ deploy app to QA namespace
deploy.qa: secrets.qa
	kubectl apply -k overlays/qa --kubeconfig=secrets/qa-bkpi.yaml
	kubectl set image deployment/bkereporting bkereporting=harbor.cis-qas.brown.edu/bkereporting/reporter:$(HASH) -n bkereporting --kubeconfig=secrets/qa-bkpi.yaml

#deploy.prod: @ deploy app to PROD namespace
deploy.prod: secrets.prod
	kubectl apply -k overlays/prod --kubeconfig=secrets/prod-bkpi.yaml
	kubectl set image deployment/bkereporting bkereporting=harbor.services.brown.edu/bkereporting/reporter:$(HASH) -n bkereporting --kubeconfig=secrets/prod-bkpi.yaml
