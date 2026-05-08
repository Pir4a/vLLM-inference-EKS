# ArgoCD Bootstrap

Bootstrap d'ArgoCD sur le cluster EKS. Une fois ces étapes faites, tout le reste (KEDA, kube-prometheus-stack, ArgoCD lui-même) est géré en GitOps via le pattern App-of-Apps.

## Prerequisites

- `kubectl` configuré sur le cluster (`aws eks update-kubeconfig --name llm-inference-sre --region us-east-1`)
- `helm` ≥ 3.x
- Le repo Git public ([github.com/Pir4a/llm-inference-sre](https://github.com/Pir4a/llm-inference-sre))

## Step 1 — Install ArgoCD via Helm

C'est l'étape *chicken-and-egg* : ArgoCD ne peut pas se déployer lui-même la première fois.

```bash
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --version 9.5.12 \
  -f k8s/platform/argocd/values.yaml
```

Cette installation manuelle est unique. Après ça, ArgoCD reprend la main sur lui-même via l'Application `argocd` définie dans `k8s/argocd/applications/argocd.yaml`.

## Step 2 — Bootstrap App-of-Apps

```bash
kubectl apply -f k8s/argocd/bootstrap/root-app.yaml
```

ArgoCD lit le dossier `k8s/argocd/applications/` et crée les 3 Applications enfants (`argocd`, `keda`, `kube-prometheus-stack`). Synchronisation automatique avec `prune` + `selfHeal`.

## Step 3 — Verify

Accès à l'UI ArgoCD :

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Mot de passe initial admin :

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Tu devrais voir **4 Applications** en `Healthy` / `Synced` : `root`, `argocd`, `keda`, `kube-prometheus-stack`.
