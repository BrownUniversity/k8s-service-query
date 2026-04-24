#local-check: @ Using the LOCALDEV=y var will pull secrets to local files.
LOCALDEV ?= no
ifeq ($(LOCALDEV), $(filter $(LOCALDEV), y Y yes Yes True true))
local-check:
	mkdir -p secrets
	op read -n op://ozxznermh2dq4gbh55do65oq7e/faibewfkmurzmth62xm5nxobva/password > secrets/robot-qa.txt
	op read -n op://ozxznermh2dq4gbh55do65oq7e/arbb4qgu676q7evi4u2ubfqiuy/password > secrets/robot-dr.txt
	op read -n op://ozxznermh2dq4gbh55do65oq7e/rujmiflx3nwpdnjohbmofqvola/password > secrets/robot-prod.txt

	op read op://ozxznermh2dq4gbh55do65oq7e/x6xih2sdzstjcwna4xnhfwyqru/qa-bkei.yaml > secrets/qa-bkei.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/fslejjfdbkkor2cpn7kfxa2hua/qa-bked.yaml > secrets/qa-bked.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/li75xnokbtcydhq6cozgb4a6z4/dr-bkei.yaml > secrets/dr-bkei.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/vblcf726cyjcai6mevaxmjg5ra/dr-bked.yaml > secrets/dr-bked.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/p3prcq4ibc4ped7hhace22uv7a/prod-bkei.yaml > secrets/prod-bkei.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/kmvnborkdzg2xrq5y5hayglrse/prod-bked.yaml > secrets/prod-bked.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/76f7tmosycmk6uugpmiom6qrru/voutil2.yaml > secrets/voutil2.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/76cr3vgu23zupmx4nlqtyvwc6y/qa-voutil2.yaml > secrets/qa-voutil2.yaml
	op read op://ozxznermh2dq4gbh55do65oq7e/22oeitbsmcfmjxz2mx453mbf7e/dr-voutil2.yaml > secrets/dr-voutil2.yaml
else
local-check: ;
endif

#clean: @ clean local-dev secrets
clean:
	rm -rf ./secrets