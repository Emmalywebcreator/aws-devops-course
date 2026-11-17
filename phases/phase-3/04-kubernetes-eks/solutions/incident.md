# Solution · 3.4 incident — "pods Running, synthetic failing"

> Not linked from the module.

## Root causes (two)

| # | Cause | Effect |
|---|---|---|
| 1 | Service selector changed from `app: orders-api` to `app: orders`. | No pod carries `app: orders` → Service has **zero endpoints** → the load balancer forwards to node ports with nothing behind them → connection errors / 503. **This is the outage.** |
| 2 | Deployment readiness probe path changed to `/healthz` (the app only serves `/health`). | New pods never become ready → rollout **stuck**. Because `maxUnavailable: 0`, the old pods keep running and *would* serve traffic — once cause 1 is fixed. |

Fixing only cause 1 restores traffic but leaves a stuck rollout (and a time bomb: the next node replacement kills an old pod that can't be replaced by a ready one). Fixing only cause 2 changes nothing for users. **Both** must be found.

## Diagnosis path

1. **Traffic path, outside in.** LB exists (`kubectl -n orders get svc orders-api` shows the hostname) → so look one step in: endpoints.
   ```bash
   kubectl -n orders get endpointslices -l kubernetes.io/service-name=orders-api -o wide
   ```
   → no addresses. "Pods Running but no endpoints" = selector mismatch **or** no ready pods.
2. **Selector vs labels:**
   ```bash
   kubectl -n orders get svc orders-api -o jsonpath='{.spec.selector}{"\n"}'     # {"app":"orders"}
   kubectl -n orders get pods --show-labels                                        # app=orders-api
   ```
   → mismatch = cause 1.
3. **Are the pods ready?**
   ```bash
   kubectl -n orders get pods          # old pods 1/1 READY; one new pod 0/1 READY
   kubectl -n orders describe pod <the 0/1 pod> | sed -n '/Events/,$p'
   ```
   → `Readiness probe failed: HTTP probe failed with statuscode: 404` = cause 2. `kubectl -n orders rollout status deployment/orders-api` hangs; `kubectl -n orders get rs` shows a new ReplicaSet with 0 ready.
4. **Why does the app say 404?** `kubectl -n orders logs <new pod>` shows `GET /healthz … 404` lines — the app is fine, the probe is wrong.

## Fix (from source of truth)

```bash
kubectl apply -f k8s/service.yaml       # selector back to app: orders-api (and type: LoadBalancer)
sed -e "s#IMAGE_URI#$IMAGE#" -e "s#IMAGE_TAG#$TAG#" k8s/deployment.yaml | kubectl apply -f -
kubectl -n orders rollout status deployment/orders-api --timeout=120s
```

Applying the repo's manifests reverts both live edits. (`kubectl rollout undo` would fix cause 2 but not cause 1 — the Service isn't part of the Deployment's history.)

## Model incident note

> **Impact:** orders-eks unreachable for ~12 min (LB → 0 endpoints); no data loss. **Root cause:** live `kubectl` edits changed the Service selector to a label no pod had, and set the readiness probe to a non-existent path, freezing the rollout. **Fix / prevention:** re-applied manifests from Git; only CI may `kubectl apply` to shared clusters, and a pre-merge check fails if a Service selector matches no Deployment's pod labels.
