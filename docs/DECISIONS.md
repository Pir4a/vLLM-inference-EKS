# Architecture Decision Records

Décisions structurantes du projet `llm-inference-sre`. Format Michael Nygard simplifié.

> Voulant experimenter avec différentes technologies pour continuer mon apprentissage du Site Reliablity Engineering, je me suis lancé dans un projet de vLLM, hosté sur AWS, en utilisant les bonnes pratiques : Gitops, IaC, Observabilité, Stress Testing, Chaos engineering.
> Le but du projet est relativement simple : faire tourner un LLM sur un cluster GPU AWS, de la façon la plus propre, maintenable et fiable.
> Ce projet me permet de mieux comprendre le fonctionnement dans un contexte "réel" d'un cluster K8s, et également de bien analyser les différentes possibilités FinOps pour garder les coûts le plus pas possible sans compromettre le rendu final.
> C'est cette vértiable ingénierie qui me motive a mener a bien ce projet.

---

## ADR-001 — Cloud : AWS

**Statut :** Acceptée
**Date :** 2026-05-02

### Contexte

Ce projet SRE/MLOps nécésite un cloud pour héberger le workload GPU, il doit répondre aux critères suivants :

- Services Kubernetes efficaces : Le Workload sera distribué via K8s, un service managé ferait gagner un temps précieux.
- Employabilité : Ce projet est aussi pour montrer ma capacité a réaliser un projet en condition proche du réel, un cloud largement utlisé est donc plus pertinant.
- Coûts : Le cloud doit être soit abordable, soit permettre des solutions FinOps efficaces (spot instances).

### Décision

AWS.

### Rationale

J'ai décidé de partir sur AWS pour le mindshare marché : la majorité des offres SRE en France demandent AWS, et je voulais un projet directement transférable.

J'ai accepté le coût GPU plus élevé que sur GCP en compensant par du spot + autoscale-to-zero.

Si le projet était à refaire sur GCP, seule la couche infra Terraform changerait fondamentalement — la couche K8s reste portable.

### Alternatives considérées

- **GCP** : pricing GPU ~30% inférieur et GKE Autopilot intéressants, mais mindshare marché plus faible en France (~15% des JD vs ~65% AWS). Écarté pour la cible employabilité.
- **Azure** : mindshare SRE le plus faible des trois, pas d'avantage clair sur le pricing GPU ou l'écosystème K8s. Écarté.

### Conséquences

- ✅ Stack directement transférable aux employeurs cibles français.
- ❌ Coût GPU plus élevé qu'sur GCP — mitigé par spot + scale-to-zero (voir ADR-005).
- ⚠️ Quotas GPU AWS non alloués par défaut → demande de quota à faire dès J0 (24-72h de validation).

---

## ADR-002 — Kubernetes : EKS managed

**Statut :** Acceptée
**Date :** 2026-05-02

### Contexte

AWS retenu (ADR-001), reste à choisir entre EKS managed et un cluster self-managé (kubeadm sur EC2).

### Décision

EKS managed.

### Rationale

J'ai pris EKS pour concentrer mon énergie sur ce qui distingue le projet. Construire un cluster à partir de zéro est très enrichissant pour la connaissance globale de Kubernetes, mais je voulais que mon focus soit sur les SLOs, le multi-burn-rate, l'autoscaling KEDA sur métriques d'inférence et l'observabilité — plutôt que sur la mécanique du control plane.

En self-managed, je gérerais notamment : backup/restore d'etcd, rotation des certificats (kubelet, api-server), HA du control plane (3 masters + load balancer), upgrades K8s manuelles version par version. Ces sujets sont importants mais hors du focus du projet.

Je pourrais refaire ce projet en kubeadm dans un side-project dédié pour rentrer dans les entrailles de Kubernetes.

### Alternatives considérées

- **kubeadm self-managed** : enrichissant pour la connaissance K8s en profondeur, mais aurait détourné 2-3 semaines vers la mécanique cluster — hors scope du focus projet (reliability workload).
- **EKS Auto Mode / Fargate** : abstraction excessive, masque la gestion des nodes GPU et l'autoscaling KEDA que je veux justement démontrer.

### Conséquences

- Coût control plane fixe : ~$73/mois (acceptable dans l'enveloppe budget).
- Upgrades K8s simplifiées (passage de version mineure via Terraform).
- Versions K8s en léger retard (~2 minor releases) sur l'upstream — acceptable au contexte.
- HA control plane gratuite et garantie par AWS.

---

## ADR-003 — Modèle & GPU : Qwen 2.5 7B sur g5.xlarge

**Statut :** Acceptée
**Date :** 2026-05-02

### Contexte

Choix du modèle d'inférence à servir et du GPU pour l'héberger, dans le contexte d'un projet portfolio (qualité acceptable mais pas optimale, coût maîtrisé).

### Décision

- Modèle : **Qwen 2.5 7B** (fp16).
- GPU : **g5.xlarge** (NVIDIA A10G, 24 GB VRAM) en spot.

### Rationale

**Modèle.** Qwen 2.5 7B est un bon compromis entre prix et qualité : suffisant pour donner des réponses cohérentes dans le contexte du projet (RAG dressage chiot) sans faire exploser les coûts.

**GPU.** Le A10G (24 GB VRAM) suffit largement pour Qwen 7B fp16 (~14 GB), avec marge confortable pour le KV-cache et un context window utilisable. Coût spot us-east-1 : ~$0.30/h.

### Alternatives considérées

- **Modèles plus petits (Qwen 1.5B / 3B)** : moins coûteux en VRAM mais qualité de réponse en chute marquée — démo moins convaincante en entretien.
- **Modèles plus gros (Qwen 14B+)** : qualité supérieure mais nécessitent A100 40GB ou quantization 4-bit. Coût et complexité disproportionnés au contexte portfolio.
- **g4dn.xlarge (T4 16 GB)** : ~$0.16/h spot, plus économique, mais 16 GB serrent pour 7B fp16 (risque OOM avec contexte long) — utilisable uniquement en quantisé.
- **g6.xlarge (L4 24 GB)** : génération plus récente, on-demand légèrement moins cher, mais pool spot moins établi en us-east-1 fin 2026 — risque d'interruptions plus fréquent.

### Conséquences

- Marge VRAM (~10 GB libres) confortable pour KV-cache et context window de plusieurs milliers de tokens.
- Dépendance au pool spot us-east-1 (interruptions à monitorer comme cas chaos).
- Action préalable : demande de quota EC2 G/VT instances à anticiper (24-72h).

---

## ADR-004 — Région : us-east-1

**Statut :** Acceptée
**Date :** 2026-05-02

### Contexte

Choix de la région AWS, sans contrainte d'utilisateurs réels à servir — l'objectif est de minimiser le coût et de maximiser la disponibilité du pool spot.

### Décision

us-east-1 (N. Virginia), AZ unique (voir ADR-006).

### Rationale

us-east-1 est la région AWS avec le plus gros pool spot et les prix on-demand les plus bas, donc la plus intéressante dans un objectif de réduction des coûts pour un projet portfolio.

### Alternatives considérées

- **eu-west-1 (Irlande)** : plus proche géographiquement (~30 ms vs ~100 ms depuis la France), mais pricing GPU ~10-15% plus élevé et pool spot plus petit. Pertinent pour de vrais users EU + RGPD.
- **eu-west-3 (Paris)** : meilleure latence (~5 ms) mais pool spot très petit (interruptions fréquentes) et certains GPU moins disponibles — incompatible avec stratégie spot.

### Conséquences

- Latence ~100 ms depuis la France — acceptable pour un projet sans utilisateurs réels.
- Pour de vrais users EU, bascule en eu-west-1 (ou multi-régions avec failover) ; surcoût ~+15% mais gain RGPD + latence.
- Données (transcripts, modèles HuggingFace) hébergées hors UE — point à rejouer dans une discussion RGPD réelle.

---

## ADR-005 — Stratégie coût : tear-down complet entre sessions

**Statut :** Acceptée
**Date :** 2026-05-02

### Contexte

Budget portfolio limité (~$15-20/mois acceptable maximum). Une infra GPU en 24/7 (~$700/mois) est inacceptable ; une stratégie de gestion fine du cycle de vie est nécessaire.

### Décision

L'infra entière est détruite via `terraform destroy` entre chaque session de dev/démo, et reconstruite via `terraform apply` au début de la suivante. Aucun état persistant ne vit dans le cluster.

### Rationale

**Scale-to-zero.** Le node GPU n'est lancé que pendant que je travaille dessus.

**Tear-down complet.** Via l'IaC, je détruis complètement l'infrastructure entre chaque session, ce qui me permet d'expérimenter avec la notion _"cattle, not pets"_ — une infra doit pouvoir être remplacée facilement.

Cela me permet également d'observer le **cold-start** (temps entre `terraform apply` et premier token Qwen servi) comme un SLI à part entière.

**Discipline GitOps.** Ce système impose un versionnement rigoureux, car il n'y a pas d'état vivant entre les sessions.

Concrètement : ~$10/mois (4 sessions de 4h en spot) vs ~$700/mois en on-demand 24/7 — un facteur ~70 d'économie pour un projet sans usage continu.

### Alternatives considérées

- **On-demand 24/7** : ~$700/mois pour le seul g5.xlarge. Incompatible avec budget portfolio.
- **Spot 24/7** : ~$220/mois, plus raisonnable mais toujours hors budget pour un projet sans usage continu, et expose aux interruptions sans bénéfice utilisateur (personne ne consomme le service la nuit).
- **Karpenter au lieu de Cluster Autoscaler + KEDA** : option valide pour le scale-to-zero node-level, mais Cluster Autoscaler + KEDA restent plus standards en entretien et suffisants pour la démo.

### Conséquences

État persistant à externaliser ou recalculer entre sessions :

- **Transcripts Esprit Dog** : versionnés dans le repo (samples publics) + originaux gitignored.
- **Embeddings vector DB** : recalculés au spin-up depuis les transcripts (option simple, ~5-10 min de cold-start). Évolution possible vers snapshot S3 si la durée devient gênante.
- **Modèle Qwen** : pull HuggingFace au démarrage (option simple) ou image ECR avec modèle baked-in (~15 GB) si trop lent.
- **Métriques Prometheus historiques** : perdues à chaque destroy. Acceptable au contexte (load tests courts, screenshots Grafana suffisent). Évolution : Grafana Cloud free tier si historique nécessaire.
- **Cold-start instrumenté** comme SLI à part entière (`terraform apply` → premier token servi).

---

## ADR-006 — Topologie : single-AZ

**Statut :** Acceptée
**Date :** 2026-05-02

### Contexte

Choix du niveau de HA infra (single-AZ vs multi-AZ), dans le contexte de la contrainte budget (ADR-005) et d'un autre projet portfolio démontrant déjà du multi-AZ.

### Décision

Single-AZ dans us-east-1a.

### Rationale

Pour ce qui est de la disponibilité, j'ai fait le choix de rester sur une seule AZ : il n'y aura pas d'utilisateurs réels qui justifierait le coût d'un déploiement multi-AZ.

Par ailleurs, j'ai déjà expérimenté un déploiement sur plusieurs AZ sur un autre projet portfolio, ce qui renforce ma conviction de me focaliser ici sur les notions de reliability du workload (SLO, autoscaling, chaos).

> 🟡 **Lien à ajouter** : URL du projet portfolio multi-AZ + URL du blog post associé.

Pour survivre à une coupure de zone, un déploiement multi-AZ voire multi-régions est indispensable en production.

### Alternatives considérées

- **Multi-AZ (2-3 AZ)** : ~$50/mois additionnels (NAT Gateway × AZ + data transfer cross-AZ). Indispensable en prod, mais redondant avec un autre projet portfolio qui le démontre déjà.

### Conséquences

- Une panne AZ = service down (acceptable pour le contexte projet).
- Réseau simplifié : 1 public subnet, 1 private subnet, 1 NAT Gateway, 1 IGW.
- Node groups (CPU et GPU) tous dans us-east-1a — pas de PodAntiAffinity cross-AZ nécessaire.

---

## ADR-007 — Terraform state : S3 native locking

**Statut :** Acceptée
**Date :** 2026-05-02

### Contexte

Le state Terraform doit vivre dans un backend distant avec locking pour éviter sa perte et empêcher les `apply` concurrents qui corrompraient le state.

### Décision

State stocké dans S3 (versioning ON, SSE, public access bloqué), avec **locking natif S3** via `use_lockfile = true` (Terraform 1.10+). Pas de DynamoDB.

### Rationale

J'ai fait du S3+DynamoDB sur un projet précédent. J'ai donc voulu expérimenter avec la nouvelle feature de S3 native locking (Terraform 1.10+, basée sur les S3 conditional writes) pour avoir un avis informé sur les deux patterns.

Pour rappel, le state locking est indispensable au travail en équipe : sans lui, deux `terraform apply` simultanés peuvent corrompre le state (l'état que Terraform connaît de l'infrastructure).

Tradeoffs honnêtes : c'est moins éprouvé en prod (feature TF 1.10+ datant de fin 2024), certains outils CI/CD (Atlantis, anciens runners) peuvent ne pas le supporter pleinement, et OpenTofu n'a aligné qu'à partir de 1.11. En équipe je resterais sur S3+DynamoDB tant que TF 1.10+ n'est pas standard partout.

### Alternatives considérées

- **S3 + DynamoDB lock** : pattern standard et éprouvé, déjà utilisé sur un projet précédent — choix de ne pas le répéter pour explorer la nouvelle approche.
- **Terraform Cloud / HCP Terraform** : free tier suffirait, mais ajoute une dépendance hors AWS et un vendor lock-in non justifié au scope.
- **Local state** : rejeté (perte du fichier = infra orpheline, pas de partage équipe possible, risque de concurrent runs corrompant le state).

### Conséquences

- `required_version >= 1.10` à pinner dans le bloc `terraform`.
- Versioning S3 critique — le locking en dépend, et sans lui aucun rollback possible en cas de corruption.
- Bootstrap manuel via script CLI (création one-shot du bucket) documenté dans `infra/bootstrap.sh`.
- Un state file par module Terraform (préfixe `<module>/terraform.tfstate` dans le bucket) → permet `apply` indépendant et lock séparé par module.

---

## ADR-008 — GitOps tooling : ArgoCD + App-of-Apps

**Statut :** Acceptée
**Date :** 2026-05-08

### Contexte

Une fois EKS provisionné via Terraform (ADR-002), il faut un mécanisme pour déployer le platform stack (Prometheus, Grafana, KEDA) et à terme la workload vLLM, et gérer leur cycle de vie. Cette couche est au-dessus de Terraform : une fois le cluster up, c'est elle qui décide ce qui tourne dedans.

L'approche GitOps permet d'avoir Git comme seule source de vérité, et donc d'itérer ou rollback rapidement et simplement, ce qui correspond également très bien à la stratégie tear-down/recreate (ADR-005).

Plusieurs familles d'options existent : outils GitOps déclaratifs pull-based (ArgoCD, Flux), wrappers déclaratifs push-based (Helmfile, Terraform `helm_release`), ou `helm install` direct depuis un Makefile / CI.

### Décision

ArgoCD avec le pattern App-of-Apps.

Layout :

- `k8s/argocd/applications/` : 3 Applications (ArgoCD self-managed, KEDA, kube-prometheus-stack)
- `k8s/argocd/bootstrap/root-app.yaml` : root Application qui watche le dossier précédent
- `k8s/argocd/README.md` : runbook bootstrap (le `helm install` initial)
- `k8s/platform/<chart>/values.yaml` : values overrides référencées depuis les Applications via le pattern multi-source

### Rationale

**Mindshare marché.** ArgoCD s'impose comme le leader GitOps actuellement, dû notamment à sa graduation en tant que projet CNCF et à sa simplicité d'utilisation pour les équipes de développement, par rapport à un Flux plus low-level. Il est plus présent que Flux dans les offres SRE françaises. Une partie du choix est explicitement portfolio-driven et je l'assume : m'améliorer sur cette technologie via ce projet est directement transférable au marché.

**UI.** Argo possède une GUI très user-friendly (Applications, sync status, ressources, diff vs Git) — rassurante en cas de démo et utile en simulation d'incident response.

**Pull-based.** ArgoCD observe directement l'état du Git pour appliquer les changements en continu, donc pas besoin d'exposer un endpoint K8s dans la CI/CD — bénéfice côté sécurité. Honnêtement, dans mon setup actuel (single-cluster, public endpoint, pas de CI qui déploie), ce bénéfice ne se matérialise pas — il deviendrait pertinent si j'ajoutais une CI ou si je passais le cluster en endpoint privé.

**Self-management.** Le chicken-and-egg : ArgoCD ne peut pas se déployer lui-même la première fois. Un `helm install` manuel one-shot suffit à le résoudre, après quoi ArgoCD reprend la main sur lui-même via l'Application `argocd` définie dans `k8s/argocd/applications/argocd.yaml`.

**Multi-source.** Grâce aux Helm charts publics et aux values overrides versionnées dans ce repo via le mécanisme `$values/path`, pas besoin de fork les charts de la communauté.

### Alternatives considérées

- **Flux** : plus low-level, pas d'UI native (`GitRepository` + `Kustomization` au lieu de `Application`), mindshare français plus faible. Pour qui privilégie le minimalisme et n'a pas besoin de l'UI, c'est valide.
- **Raw `helm install` depuis Makefile / CI** : simplissime à bootstrapper (pas de chicken-and-egg), mais perd le drift correction, l'UI, et la cohérence GitOps narrative. Acceptable pour single-cluster, mais perd un sujet d'interview classique.
- **Helmfile / Terraform `helm_release`** : wrapper déclaratif mais déclenchement push-based (un humain ou la CI doit lancer l'apply). Pas du vrai GitOps au sens "Git = état désiré, le cluster reconcile en continu".
- **ApplicationSet (au lieu d'App-of-Apps)** : pattern moderne ArgoCD qui génère N Applications à partir d'un template + un générateur (List, Cluster, Git, etc.). Pertinent en multi-cluster ou multi-env. Sur single-cluster avec 3 charts fixes, surdimensionné — App-of-Apps est plus simple à raisonner.

### Conséquences

- ✅ Repo structure App-of-Apps en place (`k8s/argocd/applications/`, `k8s/argocd/bootstrap/`). Ajouter une workload future = écrire une nouvelle Application CRD, pas de modif infra Terraform.
- ✅ Runbook bootstrap documenté (`k8s/argocd/README.md`) — un recruteur peut reproduire le setup à zéro.
- ✅ Multi-source permet de pinner le chart upstream et de versionner les values dans Git sans fork.
- ✅ Coût runtime négligeable : 1-2 pods ArgoCD (server, repo-server, application-controller) tiennent sur le node CPU `t3.medium` existant.
- ⚠️ Bootstrap manuel `helm install` à chaque création de cluster (chicken-and-egg). Étape ~1 min, documentée, mais friction réelle dans la stratégie tear-down/recreate (ADR-005).
- ⚠️ Pas de stratégie secrets définie. Dès qu'un secret arrivera dans le repo (token HuggingFace, mot de passe Grafana custom), il faudra trancher entre Sealed Secrets, SOPS, et External Secrets Operator → ADR séparé à venir.
- ❌ Pour ce projet (single-cluster, single-env, 3 charts), ArgoCD est honnêtement over-spec. Un `Makefile` avec `helm upgrade --install` ferait le même travail correctement en 30 secondes par session, sans chicken-and-egg. Le choix est assumé comme investissement portfolio, pas comme nécessité opérationnelle.
- ❌ La stratégie tear-down/recreate ne se marie pas idéalement avec ArgoCD : à chaque destroy/recreate du cluster, ArgoCD doit reboot, re-discover Git, re-sync les 3 Applications. Une infra long-running en bénéficierait davantage.

---

## ADR-009 — EKS Kubernetes version : 1.34 (N-1)

**Statut :** Acceptée
**Date :** 2026-05-08

### Contexte

EKS supporte plusieurs versions Kubernetes simultanément avec une cadence de release upstream (~3 minor releases/an) et une politique de support standard AWS de ~14 mois par version, suivie d'extended support payant (~$0.60/h supplémentaire par cluster).

Le choix de version se fait dans `infra/variables.tf` et impacte :

- la stabilité opérationnelle (bugs, edge cases, ecosystem maturity)
- la disponibilité de features récentes (sidecar containers, structured authentication config, etc.)
- la compatibilité des charts Helm community (kube-prometheus-stack, KEDA, future addons)
- la fenêtre avant prochaine upgrade obligatoire

### Décision

**Kubernetes 1.34**, soit N-1 au moment de démarrer le projet (N = 1.35 sur EKS).

### Rationale

**N-1 comme sweet spot stabilité.** Au moment du choix, 1.34 a déjà ~6 mois de production sur EKS, donc les bugs early adopter sont déjà remontés et patchés, les charts Helm community ont eu le temps de valider leur compatibilité, et la documentation AWS / blog posts couvrent les edge cases courants.

**N (latest) écarté pour le risque early adopter.** Sur les versions tout juste GA, les charts community ne sont pas tous validés en prod, certains addons EKS (VPC CNI, EBS CSI) peuvent avoir des combos non testés, et les rapports de bugs CVE sortent plus fréquemment.

**N-2 ou inférieur écarté pour la fenêtre EOL.** Plus on prend une version ancienne, plus on rapproche la fin de support standard et donc soit l'upgrade obligatoire, soit le passage en extended support payant (~$430/mois pour le cluster — non-négligeable pour un projet portfolio).

**Marge d'upgrade.** Avec 1.34 = N-1 et la stratégie tear-down/recreate (ADR-005), bumper la version se fait par modification d'une seule variable Terraform et `terraform apply`. Pas d'in-place upgrade complexe à coordonner avec les workloads.

### Alternatives considérées

- **EKS 1.35 (N)** : version la plus récente, mais charts kube-prometheus-stack et KEDA pas tous validés en prod sur cette version au moment du choix. Bénéfice marginal au regard des features dont j'ai besoin pour le projet.
- **EKS 1.33 (N-2)** : encore en support standard mais fenêtre plus courte avant EOL, sans bénéfice clair vs 1.34. Aurait été pertinent si une dépendance critique l'avait imposée — ce n'est pas le cas.
- **EKS Auto Mode** : abstrait la version K8s sous-jacente (AWS la gère). Écarté côté ADR-002 (masque la gestion de nodes GPU et l'autoscaling KEDA que je veux démontrer).

### Conséquences

- ✅ kube-prometheus-stack 84.5.0 compatible (supporte K8s 1.30+).
- ✅ KEDA 2.19.0 compatible (supporte K8s 1.27+).
- ✅ ArgoCD 9.5.x compatible (supporte K8s 1.27+).
- ✅ La stratégie tear-down/recreate (ADR-005) facilite les upgrades : un changement de version dans `infra/variables.tf` suivi d'un `terraform apply` recrée le cluster sur la nouvelle version, sans coordination avec des workloads stateful.
- ⚠️ Fenêtre de support standard à surveiller : 1.34 sort de standard support EKS environ 14 mois après sa GA EKS — à re-vérifier sur la doc officielle AWS au moment de la prochaine session de dev. Plan : bump vers 1.35 ou 1.36 avant cette date pour rester en standard support gratuit.
- ⚠️ Cet ADR est à mettre à jour après chaque bump de version (mettre la date, marquer le précédent comme superseded ou ajouter une note).
- ❌ Ce projet ne tire aucun bénéfice spécifique des features 1.34 vs 1.33 ou 1.35 — le choix est conservateur, pas optimisé. Sur un projet réel avec un besoin précis (par ex. une feature passée GA récemment et utile au workload), j'aurais probablement bumped à N pour la feature.
