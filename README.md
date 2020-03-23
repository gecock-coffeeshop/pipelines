### Coffeeshop Continuous Deployment with Tekton

This repo contains Tekton resources for continuous deployment of the Coffeeshop demo.

**Pipelines**

1. Install the OpenShift Pipelines Operator from OperatorHub.
1. Create a personal access token on GitHub with the `public_repo` scope.
1. Update the `password` field in the `pipeline/git-secrets.yaml` file to the personal access token created in the previous step.
1. Deploy the pipeline components:
   * `oc create ns coffeeshop-pipelines`
   * `oc apply -f serviceaccount.yaml`
   * `oc apply -f pipeline/git-secrets.yaml`
   * `oc apply -f pipeline/pipeline-clusterroles.yaml`
   * `oc apply -f pipeline/task-deploy.yaml`
   * `oc apply -f pipeline/task-tests.yaml`
   * `oc apply -f pipeline/pipeline-resources.yaml`
   * `oc apply -f pipeline/pipeline-deploy.yaml`
1. Now you can manually run the pipeline which will deploy your resources. (Currently you will also need to have deployed `triggers/git-secrets` otherwise the pipeline will fail)
   * `oc create -f pipeline/run-pipeline.yaml`

**Triggers**

1. In the `ingress.yaml` file, substitute `<INGRESS_ROUTER_HOSTNAME>` with the canonical hostname for the OpenShift ingress router. For example: `host: eventlistener.apps.mycluster.myorg.com`. This can be found by either:
   * using the OpenShift UI, find the `ROUTER_CANONICAL_HOSTNAME` environment variable defined in the `router-default` deployment in the `openshift-ingress` project,
   * via the command line as follows:  
   `oc describe deployment router-default -n openshift-ingress | grep HOSTNAME`
1. Update the `webhooksecret` field in the `trigger/git-secrets.yaml` file to a randomly generated secret.
1. Create webhook on GitHub, specifying:
   * "Payload URL" as `http://eventlistener.<HOST>:80` where host is the same as from the ingress file above.
   * "Secret" as the `webhooksecret` from `trigger/git-secrets.yaml`.
   * "Content-Type" as `application/json`.
   * In "Events" leave the "Just the push event" trigger option selected.
1. Deploy the trigger components:
   * `oc apply -f trigger/git-secrets.yaml`
   * `oc apply -f trigger/pipeline-roles.yaml`
   * `oc apply -f trigger/eventlistener.yaml`
   * `oc apply -f trigger/triggertemplate.yaml`
   * `oc apply -f trigger/triggerbindings.yaml`
   * `oc apply -f trigger/ingress.yaml`

**Dashboard**

1. Generate a password and enter the following in your command line `export PASSWORD=<password you created>`. The next script will use this variable to generate the certificate.
1. Create the certificate and key:  
`dashboard/generate-tls-certs.sh`
1. In the `dashboard/tekton-dashboard-secret.yaml` file you will need to replace the `tls.crt` and `tls.key` values with the certificate and key that was generated from the previous script. Use the following commands to encode the files to replace the above values with:
   * `echo dashboard/tekton-key.pem | base64 -w 0`
   * `echo dashboard/tekton-cert.pem | base64 -w 0`
1. In the `ingress.yaml` file, substitute `INGRESS_ROUTER_HOSTNAME` with the canonical hostname for the OpenShift ingress router. For example: `host: tekton.dashboard.apps.mycluster.myorg.com`. This can be found by either:
   * using the OpenShift UI, find the `ROUTER_CANONICAL_HOSTNAME` environment variable defined in the `router-default` deployment in the `openshift-ingress` project,
   * via the command line as follows:  
   `oc describe deployment router-default -n openshift-ingress | grep HOSTNAME`
1. Deploy the dashboard components.
   * `oc create ns tekton-pipelines`
   * `oc apply -f https://github.com/tektoncd/dashboard/releases/download/v0.5.2/openshift-tekton-dashboard-release.yaml --validate=false`
   * `oc apply -f dashboard/tekton-dashboard-secret.yaml`
   * `oc apply -f dashboard/ingress.yaml` 
1. You can find the url for the dashboard in the `Routes` in the `tekton-pipelines` project.
