# llm-inference-sre

SRE/MLOps portfolio project — vLLM inference on Kubernetes with KEDA autoscaling and Prometheus multi-window multi-burn-rate SLOs.

## Required: invoke portfolio-mentor skill

Before doing any work in this repo (reading, designing, writing code, answering questions), **invoke the `portfolio-mentor` skill**. It calibrates assistance into 3 zones (green / orange / red) so the user can defend every line of the repo in interviews and write authentic blog posts.

If the skill is not available in this session, manually apply its rule of thumb:

- **Green** (delegate freely): Helm/Terraform boilerplate, YAML, PromQL simple, k6 scripts, Grafana JSON, CI configs.
- **Orange** (dialogue, never generate first drafts): architecture choices, SLI/SLO design, scaling strategy, repo structure, DECISIONS.md content.
- **Red** (refuse to write the first draft, point to primary docs): vLLM Prometheus instrumentation, multi-window multi-burn-rate PrometheusRule, KEDA ScaledObject CRD, any topic the user has marked as a future blog post.

The full skill is at `~/.claude/skills/portfolio-mentor/SKILL.md`.
