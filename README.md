# homelab-genesis

This repository provides a simple GitOps path to:
1. Create a Google Kubernetes Engine cluster with OpenTofu.
2. Install Argo CD on the new cluster.
3. Use Argo CD to deploy a reachable DNS service into Kubernetes.

## 1) Prerequisites

- A GCP project with billing enabled.
- `gcloud` installed and authenticated.
- `kubectl` installed.
- `tofu` or `terraform` installed.
- A GitHub repository containing this directory structure.

Authenticate with GCP:

```bash
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT_ID
```

## 2) Provision the GKE cluster with OpenTofu

```bash
cd opentofu
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your project id

tofu init
tofu plan
tofu apply
```

After apply, the output includes a `get_credentials_command` that you can run:

```bash
gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-id>
```

## 3) Bootstrap Argo CD

Create a local environment file from the example:

```bash
cp .env.example .env
# edit .env with your values
```

Then run the bootstrap script:

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

This will:
- fetch cluster credentials,
- install Argo CD,
- create an Argo CD Application that points at `manifests/netbird-dns`,
- create the namespace and deploy the DNS service.

## 4) Access Argo CD

Port-forward the Argo CD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open https://localhost:8080 and log in as `admin` using the initial password from:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## 5) Expected result

Argo CD should sync the DNS workload under the `netbird-dns` namespace. The service exposes a `LoadBalancer` so you can reach it from the network.

## 6) Teardown / halt

To delete the cluster and stop paying for it:

```bash
cd opentofu
tofu destroy
```

## Notes

- The DNS example here is intentionally minimal and uses CoreDNS forwarding to public resolvers.
- For a real NetBird-integrated DNS setup, replace the placeholder CoreDNS config with your actual DNS server or resolver configuration.
- Consider using a private DNS zone, Cloud DNS, or a dedicated ingress/controller if you need production-grade routing.
