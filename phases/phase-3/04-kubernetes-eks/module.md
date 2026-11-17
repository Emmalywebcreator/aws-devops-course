---
phase: "phase-3"
moduleId: "3.4"
title: "Kubernetes on EKS: re-deploy the same app"
goal: "Run the same `aws-devops-platform` image you ship to ECS on an EKS cluster \u2014 declare it, roll it forward and back, expose it to the internet \u2014 and tear the cluster down without leaving a load balancer, NAT Gateway or disk behind."
timeEstimate: "5-7h"
costEstimate: "<$1.60"
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's unit prices as of 2026-11-17 (not yet checked against AWS pricing pages); if you skip teardown \u2248 $5.60/day"
lastVerified: null
prerequisites: ["0.6", "2.9", "3.1"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  "eks-kubernetes": "1.36"
  "kubectl": "v1.36.6"
  "eksctl": "v0.231.0"
  "awscli": "2.33.14"
---

# Phase 3 · Module 3.4 — Kubernetes on EKS: re-deploy the same app

## 1. Goal

Run the same `aws-devops-platform` image you ship to ECS on an EKS cluster — declare it, roll it forward and back, expose it to the internet — and tear the cluster down without leaving a load balancer, NAT Gateway or disk behind.

## 2. Prerequisites

- **Gates:** [Phase 0 exit gate](../../../assessments/gate-rules.md#part-2-the-phase-0-exit-gate-module-06) passed **and Phase 2 complete** (repo matches [the Phase 2 exit contract](../../phase-2/CONTRACT.md)). You need an image in ECR `aws-devops-platform` tagged `sha-…` (contract §2–3).
- **Modules:** [3.1 Multi-environment Terraform](../01-multi-env-terraform/module.md) (for `release.auto.tfvars` — this module reads the dev image tag from it).
- **You must already understand:** ECS task vs service, target health checks, rolling deploys (Phase 2), VPC public subnets and why NAT Gateways cost money (Phase 0 module 0.5).
- **Tools:** AWS CLI 2.33.14; installed in Lab 1: kubectl **v1.36.6**, eksctl **v0.231.0**.

## 3. Time estimate

**5–7 hours**, including **~20 min** waiting for cluster creation and **~10–15 min** for deletion. (Lab 1: 45 min · Lab 2: 1 h · Lab 3: 45 min · Lab 4: 45 min · Incident: 1 h · Teardown: 20 min.) **Do the whole module in one sitting** — the cluster bills by the hour.

## 4. Cost estimate

| Resource | Billed while idle? | Unit price (assumption) | Expected use | Cost |
|---|---|---|---|---|
| EKS control plane (standard support) | **yes** | USD 0.10/hour | ≤ 7 h | ≤ USD 0.70 |
| 2 × EC2 `t3.medium` nodes | **yes** | USD 0.0416/hour each | ≤ 7 h | ≤ USD 0.58 |
| 2 × 20 GiB gp3 node volumes | yes | USD 0.08/GB-month | ≤ 7 h | ≤ USD 0.03 |
| Public IPv4 on 2 nodes | yes | USD 0.005/hour each | ≤ 7 h | ≤ USD 0.07 |
| Classic Load Balancer (Lab 4 + incident) | **yes** | ≈ USD 0.025/hour + USD 0.008/GB processed | ≤ 3 h | ≤ USD 0.08 |
| Public IPv4 on the load balancer | yes | USD 0.005/hour per IP (≈ 2 IPs) | ≤ 3 h | ≤ USD 0.03 |
| NAT Gateway | would be **yes** | ≈ USD 0.045/hour + USD 0.045/GB processed — eksctl's **default** creates one (≈ USD 1.08/day idle); **disabled in the cluster config** | 0 | USD 0 |

- **Pricing assumptions:** Region `us-east-1`; on-demand Linux; Kubernetes **1.36** (in EKS standard support until 2 Aug 2027 — extended support costs more: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html); no free tier. Two Availability Zones (pinned in `cluster.yaml`), so the load balancer has ≈ 2 public IPs; data processed by the load balancer is negligible at lab traffic (< 1 GB). Unit prices are the author's figures as of 2026-11-17, **not yet checked** against https://aws.amazon.com/eks/pricing/, https://aws.amazon.com/ec2/pricing/on-demand/, https://aws.amazon.com/elasticloadbalancing/pricing/, https://aws.amazon.com/vpc/pricing/.
- **Total if you follow teardown:** under **USD 1.60**.
- **If you skip teardown: ≈ USD 5.60/day** (0.10 + 0.083 + 0.004 + 0.01 + 0.025 + 0.01 = 0.232/hour × 24). This is the most expensive thing to forget in the course — Lab 1 has you set a reminder.

## 5. Concepts

### Why Kubernetes, if ECS already works?

ECS is AWS-only and simpler. **Kubernetes** is the same API on every cloud and on-prem, with a huge ecosystem — which is why so many job descriptions ask for it. The skill this module builds is **mapping what you already know** onto Kubernetes objects, not starting over:

| You know (ECS) | Kubernetes equivalent | What's different |
|---|---|---|
| Task definition | **Pod** spec (inside a Deployment) | Pods are usually never created directly |
| Service (desired count, rolling deploy) | **Deployment** (+ ReplicaSet) | Keeps history; `kubectl rollout undo` |
| Target group + health check | **Service** + **readiness probe** | A pod only receives traffic while *ready* |
| ALB | **Service `type: LoadBalancer`** (or Ingress) | Kubernetes asks AWS to create the LB for you |
| Cluster (capacity provider) | **Nodes** (EC2 in a managed node group) | You pay for nodes whether pods use them or not |

Sources: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/ · https://kubernetes.io/docs/concepts/services-networking/service/

### EKS and eksctl

**Amazon EKS** runs the Kubernetes *control plane* for you (USD 0.10/hour). **eksctl** creates the cluster, VPC and node group from one YAML file via CloudFormation. **By default eksctl creates a NAT Gateway** for private subnets; this module turns it off and puts nodes in **public subnets** — the same no-NAT trade-off as Phase 2 (nodes get public IPs, protected by security groups).
Source: https://eksctl.io/usage/vpc-networking/ (NAT gateway options)

### Desired state

You don't tell Kubernetes *what to do*; you tell it *what should exist* (`kubectl apply -f`). Controllers keep working until reality matches. That's why a broken readiness probe doesn't cause an error message — it causes a rollout that **never finishes**.

### Labels and selectors

A Service finds its pods by **label selector** (`app: orders-api`). If the selector matches no ready pods, the Service has **no endpoints** — traffic goes nowhere, even though every pod is "Running". This is the #1 "it's up but it's down" Kubernetes incident.

---

## 6. Labs

> **Region:** `us-east-1` for every lab. `export AWS_REGION=us-east-1 AWS_PROFILE=<your-admin-profile>`. Work in your `aws-devops-platform` repo on `git switch -c phase3/eks`; manifests go in `k8s/`.

### Lab 1 — Install tools and create the cluster (no NAT)

- **Region:** `us-east-1`
- **Task:**

```bash
mkdir -p ~/.local/bin
curl -fsSLo ~/.local/bin/kubectl https://dl.k8s.io/release/v1.36.6/bin/linux/amd64/kubectl && chmod +x ~/.local/bin/kubectl
curl -fsSL https://github.com/eksctl-io/eksctl/releases/download/v0.231.0/eksctl_Linux_amd64.tar.gz | tar xz -C ~/.local/bin eksctl
kubectl version --client          # expect: Client Version: v1.36.6
eksctl version                    # expect: 0.231.0
```

(macOS/ARM: replace `linux/amd64` / `Linux_amd64` with your platform from the same release.)

Create `infra/eks/cluster.yaml` (kept **out of** `k8s/`, which holds only Kubernetes manifests — kubectl can't apply an eksctl config):

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: orders-eks
  region: us-east-1
  version: "1.36"
  tags:
    course: aws-devops-platform
    phase: "3"
    env: eks-lab
availabilityZones: ["us-east-1a", "us-east-1b"]   # pinned: fixes subnet/IP count and avoids AZs without t3 capacity
vpc:
  nat:
    gateway: Disable          # no NAT Gateway — nodes live in public subnets
managedNodeGroups:
  - name: ng-default
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 2
    maxSize: 2
    volumeSize: 20
    privateNetworking: false
    tags:
      course: aws-devops-platform
      env: eks-lab
```

**Set a phone reminder for 7 hours from now: "DELETE EKS CLUSTER".** Then:

```bash
eksctl create cluster -f infra/eks/cluster.yaml        # ~15–20 minutes; writes your kubeconfig
```

- **Expected result:** eksctl ends with `EKS cluster "orders-eks" in "us-east-1" region is ready`.
- **Verification command:**

```bash
kubectl get nodes -o wide
# expect: 2 nodes, STATUS Ready, VERSION v1.36.x, each with an EXTERNAL-IP

VPC_ID="$(aws eks describe-cluster --name orders-eks --query cluster.resourcesVpcConfig.vpcId --output text)"
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC_ID" \
  --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text
# expect: no output — no NAT Gateway
```

- **Teardown command:** `eksctl delete cluster -f infra/eks/cluster.yaml --wait` (at module end — section 9 has the full, ordered version).
- **Cost note:** ≈ USD 0.20/hour from this moment until deletion.

### Lab 2 — Deploy the same image

- **Region:** `us-east-1`
- **Task:** create `k8s/namespace.yaml`, `k8s/deployment.yaml`, `k8s/service.yaml`.

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: orders
```

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-api
  namespace: orders
  labels: { app: orders-api }
spec:
  replicas: 2
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxUnavailable: 0, maxSurge: 1 }
  selector:
    matchLabels: { app: orders-api }
  template:
    metadata:
      labels: { app: orders-api }
    spec:
      containers:
        - name: app
          image: IMAGE_URI            # replaced at apply time — never "latest"
          ports: [{ containerPort: 8000 }]
          env:
            - { name: APP_VERSION, value: IMAGE_TAG }
            - { name: LOG_LEVEL, value: INFO }
          readinessProbe:
            httpGet: { path: /health, port: 8000 }
            periodSeconds: 5
          livenessProbe:
            httpGet: { path: /health, port: 8000 }
            initialDelaySeconds: 10
            periodSeconds: 10
          resources:
            requests: { cpu: 100m, memory: 128Mi }
            limits: { memory: 256Mi }
```

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-api
  namespace: orders
spec:
  type: ClusterIP
  selector: { app: orders-api }
  ports: [{ port: 80, targetPort: 8000 }]
```

Apply with the dev image (same bits as ECS):

```bash
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
TAG="$(sed -E 's/.*"(.*)".*/\1/' infra/envs/dev/release.auto.tfvars)"
IMAGE="$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aws-devops-platform:$TAG"
kubectl apply -f k8s/namespace.yaml
sed -e "s#IMAGE_URI#$IMAGE#" -e "s#IMAGE_TAG#$TAG#" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl -n orders rollout status deployment/orders-api --timeout=180s
```

The nodes can pull from your private ECR because eksctl gives the node group's IAM role read access to ECR.

- **Expected result:** `deployment "orders-api" successfully rolled out`; 2 pods `Running` and `READY 1/1`.
- **Verification command:**

```bash
kubectl -n orders get pods -l app=orders-api
kubectl -n orders get endpointslices -l kubernetes.io/service-name=orders-api -o wide
# expect: 2 endpoint addresses
kubectl -n orders port-forward service/orders-api 8080:80 >/dev/null & sleep 3
curl -s localhost:8080/health; echo; curl -s localhost:8080/version; echo; kill %1
# expect: {"status":"ok"} and {"version":"<TAG>"}
```

- **Teardown command:** `kubectl delete namespace orders` (at module end).
- **Cost note:** no extra AWS cost — pods run on the nodes you already pay for.

### Lab 3 — Roll forward, break a rollout, roll back

- **Region:** `us-east-1`
- **Task:**

```bash
kubectl -n orders set image deployment/orders-api app="$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/aws-devops-platform:sha-doesnotexist"
kubectl -n orders rollout status deployment/orders-api --timeout=60s; echo "exit: $?"
kubectl -n orders get pods -l app=orders-api
```

- **Expected result:** `rollout status` times out (non-zero exit). One new pod shows `ErrImagePull`/`ImagePullBackOff`; the **two old pods stay Running** — `maxUnavailable: 0` means Kubernetes never removed working pods. Users are unaffected.
- **Roll back:**

```bash
kubectl -n orders rollout history deployment/orders-api
kubectl -n orders rollout undo deployment/orders-api
kubectl -n orders rollout status deployment/orders-api --timeout=120s
```

- **Verification command:** `kubectl -n orders get deploy orders-api -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'` → ends with your real `:$TAG`; `kubectl -n orders get pods` → 2 Running, 0 in `ImagePullBackOff`.
- **Teardown command:** none (rollback restored the good state).
- **Cost note:** USD 0 extra.

### Lab 4 — Expose it to the internet

- **Region:** `us-east-1`
- **Task:** change `k8s/service.yaml` to `type: LoadBalancer` and apply. Without extra controllers installed, EKS's built-in AWS cloud provider creates a **Classic Load Balancer** for this Service. (Source: https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html — without the AWS Load Balancer Controller, a `LoadBalancer` Service gets a Classic Load Balancer.)

```bash
sed -i 's/type: ClusterIP/type: LoadBalancer/' k8s/service.yaml
kubectl apply -f k8s/service.yaml
kubectl -n orders get service orders-api -w     # wait until EXTERNAL-IP shows a hostname, then Ctrl+C
```

- **Expected result:** `EXTERNAL-IP` becomes `<something>.us-east-1.elb.amazonaws.com`. DNS may take 1–3 minutes.
- **Verification command:**

```bash
LB_HOST="$(kubectl -n orders get service orders-api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
curl -fsS "http://$LB_HOST/health"           # expect: {"status":"ok"}
aws elb describe-load-balancers --query "LoadBalancerDescriptions[?DNSName=='$LB_HOST'].LoadBalancerName" --output text
# expect: one name — this is the AWS resource Kubernetes created for you
```

- **Teardown command:** **before deleting the cluster**, always `kubectl -n orders delete service orders-api` and wait until the `aws elb describe-load-balancers` command above prints nothing. A load balancer Kubernetes created is **not** in eksctl's CloudFormation stacks — delete the cluster first and it's orphaned, still billing, and can block VPC deletion.
- **Cost note:** ≈ USD 0.035/hour while the LB exists.

## 7. Debugging lab (incident)

- **Scenario — the page you get:**

> 🚨 **PagerDuty — 09:31 — orders-eks synthetic check FAILED: `GET http://<lb>/health` → connection error / 503 for 3 min.** `kubectl get pods`: everything `Running`. A teammate says they did "a quick label tidy-up and a probe fix" at 09:25 with `kubectl` directly. **You're on call: restore traffic first, then get the rollout healthy, and list every cause.**

- **How to create the broken state** (Lab 4's LoadBalancer Service must exist):

```bash
export COURSE=<path to your clone of this course repo>
bash "$COURSE/phases/phase-3/04-kubernetes-eks/labs/incident-no-endpoints/break.sh"
```

- **Symptom you will see:** `curl http://$LB_HOST/health` fails or returns 503 within a minute; `kubectl -n orders get pods` shows pods `Running`.
- **Your task:** using only `kubectl get/describe` (pods, service, endpointslices, deployment, replicasets), `kubectl get events`, `kubectl rollout status/history` and `kubectl logs`, find **every** cause. Fix them by re-applying your repo's manifests — `kubectl apply -f k8s/service.yaml` and the same `sed … k8s/deployment.yaml | kubectl apply -f -` pipeline as Lab 2 (your manifests are the source of truth — don't hand-edit live objects). Write a 3-line incident note.
- **Done when:**

```bash
kubectl -n orders get endpointslices -l kubernetes.io/service-name=orders-api -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | wc -l   # 2
kubectl -n orders rollout status deployment/orders-api --timeout=60s                       # successfully rolled out
curl -fsS "http://$LB_HOST/health"                                                          # {"status":"ok"}
```

- **Teardown:** none beyond section 9.

Diagnosis path: `solutions/incident.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Map these ECS ideas to Kubernetes objects: task definition, service desired count, target group health check, ALB.
2. In Lab 3, why did users see no errors even though the new pods couldn't start? What setting made that true?
3. Show the command that lists the endpoints behind a Service. What does an empty list mean, and name two different causes.
4. What's the difference between a readiness probe and a liveness probe? What happens to a pod failing each?
5. Why must you delete `type: LoadBalancer` Services *before* `eksctl delete cluster`? How do you prove the LB is gone?
6. What did `vpc.nat.gateway: Disable` save you, per day, and what's the trade-off?
7. Why does this module pin Kubernetes to 1.36 instead of "the newest", and what happens to cost if you stay on a version past its standard-support date?

## 9. Teardown

**Order matters** — Kubernetes-created AWS resources first, then the cluster.

```bash
export AWS_REGION=us-east-1
VPC_ID="$(aws eks describe-cluster --name orders-eks --query cluster.resourcesVpcConfig.vpcId --output text)"
echo "Cluster VPC: '$VPC_ID'"   # must be vpc-…; WRITE IT DOWN — the confirm step needs it after the cluster is gone

# 1. Delete the LoadBalancer Service and wait (up to 10 min) for AWS to remove the CLB
kubectl -n orders delete service orders-api --ignore-not-found
n=1
for i in $(seq 1 60); do
  n="$(aws elb describe-load-balancers --query "length(LoadBalancerDescriptions[?VPCId=='$VPC_ID'])" --output text)"
  [ "$n" = "0" ] && break; sleep 10
done
echo "Load balancers left in the cluster VPC: $n"   # must be 0 before step 3

# 2. Delete the app namespace
kubectl delete namespace orders --ignore-not-found --wait

# 3. Delete the cluster, node group and VPC (CloudFormation stacks) — ONLY if step 1 printed 0
if [ -n "$VPC_ID" ] && [ "$n" = "0" ]; then
  eksctl delete cluster -f infra/eks/cluster.yaml --wait      # ~10–15 minutes
else
  echo "STOP: a load balancer still exists (or VPC_ID is empty). Deleting the cluster now would orphan it."
  echo "Find it: aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].[LoadBalancerName,VPCId]' --output text"
fi
```

**Confirm nothing is left:**

```bash
aws eks list-clusters --query 'clusters[?@==`orders-eks`]' --output text                       # expect: no output
aws cloudformation list-stacks \
  --query "StackSummaries[?starts_with(StackName, 'eksctl-orders-eks') && StackStatus!='DELETE_COMPLETE'].[StackName,StackStatus]" \
  --output text                                                                                # expect: no output
aws elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text
                                                                                               # expect: no output
aws ec2 describe-instances --filters Name=tag:eks:cluster-name,Values=orders-eks Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[].Instances[].InstanceId' --output text                                # expect: no output
aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[].VolumeId' --output text
                                                                                               # expect: no output (no detached disks)
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC_ID" Name=state,Values=pending,available \
  --query 'NatGateways[].NatGatewayId' --output text                                           # expect: no output
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" 2>&1 | grep -q InvalidVpcID.NotFound && echo "VPC gone"   # expect: VPC gone
```

If a stack is `DELETE_FAILED`, the usual cause is an orphaned load balancer or ENI in the VPC: run step 1's `describe-load-balancers` without the VPC filter, delete what's left, then re-run `eksctl delete cluster`.

Merge `phase3/eks` with `k8s/` and `infra/eks/cluster.yaml` (Service back to `type: ClusterIP` as the committed default).

## 10. Last verified

- **Date:** NOT YET VERIFIED — drafted 2026-11-17.
- **Verified by:** —
- **Region:** `us-east-1`
- **Versions:** Kubernetes / EKS 1.36 · kubectl v1.36.6 · eksctl v0.231.0 · AWS CLI 2.33.14 · node AMI: eksctl default for 1.36 (record the AMI ID from `kubectl get nodes -o wide` / the node group)
- **Notes:** versions read from dl.k8s.io, GitHub releases and the EKS version page on 2026-11-17 (1.37, 1.36, 1.35, 1.34 in standard support). No command run against AWS. Default CLB behaviour confirmed against the EKS docs by the qa agent on 2026-11-17.
