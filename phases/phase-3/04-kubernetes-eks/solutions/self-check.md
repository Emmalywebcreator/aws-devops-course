# Solution · 3.4 self-check

> Not linked from the module.

1. Task definition → Pod template inside a **Deployment**; service desired count → Deployment `replicas`; target-group health check → **readiness probe** (deciding whether a pod gets Service traffic); ALB → **Service `type: LoadBalancer`** (or an Ingress with a load-balancer controller).
2. `maxUnavailable: 0` (with `maxSurge: 1`): Kubernetes adds one new pod first and removes an old one only after the new one is ready. The new pod never became ready, so both old pods kept serving.
3. `kubectl -n orders get endpointslices -l kubernetes.io/service-name=orders-api`. Empty = the Service has nowhere to send traffic. Causes: the selector matches no pod labels; matching pods exist but none are ready (readiness failing, crash looping, still starting).
4. Readiness: "can this pod receive traffic now?" — failing removes it from Service endpoints but doesn't restart it. Liveness: "is this container stuck?" — failing makes the kubelet **restart** the container.
5. The CLB was created by Kubernetes' cloud provider, not by eksctl's CloudFormation stacks, so deleting the cluster doesn't delete it — it keeps billing and its ENIs/security group can make the VPC stack fail to delete (`DELETE_FAILED`). Prove: `aws elb describe-load-balancers` filtered by the cluster VPC returns 0.
6. A NAT Gateway ≈ USD 0.045/hour + data processing ≈ **USD 1.08/day** minimum (Phase 0 module 0.5 figure). Trade-off: nodes need public IPs (≈ USD 0.005/h each) and sit in public subnets, so security groups are the only thing between them and the internet.
7. Pinning makes the module reproducible and lets you read that version's change notes. 1.36 is in standard support until 2 Aug 2027; after a version's standard support ends, the cluster moves to **extended support**, billed at a higher per-cluster-hour rate, and is eventually auto-upgraded.
