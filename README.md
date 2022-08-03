# K8S Service Query

This is a kubernetes application that produces HTML reports of the BKE and Rancher
clusters resources and nodes. Code is auto-deployed from the GHRunner service
on push to qa (for QA) and releases in main (for PROD).

## Requirements

* gnu Makefile
* kubectl
* blackbox
* Docker
* Python
  * kubernetes module

## Development and Release

Clone repo and develop in either the `qa` branch or a new branch. `main` is 
protected against pushes. 

**DO NOT DEV IN `main`!**

Push/Merge your code into `qa`. This will trigger a GitHub action, which will  

* build a QA image
* push that QA image to harbor
* deploy the app to QA

Once you are satisfied with QA, you merge to `main`. No PROD action is triggered
until a release is created. Please use [semantic versioning](https://semver.org/).

The GitHub will repeat the process for PROD. 

## Important Files

* namespaces.py, nodes.py: These are the main code that produces the reports. They 
use the kubernetes python module and ingest the kubeconfig secrets 
* base, overlays: These are the [Kustomize](https://kustomize.io/) app files for
deploying the application.
* Makefile: Defines the commands to perform the build, push, deploy, etc.
* Dockerfile: Defines how to build the new reporter image
* requirement.txt: Python requirements file for modules