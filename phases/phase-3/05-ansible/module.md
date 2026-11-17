# Phase 3 · Module 3.5 — Ansible: configuration management for the hosts you can't containerise away

## 1. Goal

Configure two EC2 hosts to run the `aws-devops-platform` container under systemd from one idempotent Ansible playbook with a dynamic AWS inventory, roll a config change across them one at a time, and find and undo a manual change on one host.

## 2. Prerequisites

- **Gates:** [Phase 0 exit gate](../../../assessments/gate-rules.md#part-2-the-phase-0-exit-gate) passed **and Phase 2 complete** (repo matches [the Phase 2 exit contract](../../phase-2/CONTRACT.md)); an image `sha-…` exists in ECR `aws-devops-platform`.
- **Modules:** [3.1 Multi-environment Terraform](../01-multi-env-terraform/module.md) (reads the dev image tag from `release.auto.tfvars`).
- **You must already be able to:** SSH to an EC2 instance with a key pair and a security group limited to your IP (Phase 0 module 0.5); write and apply Terraform (Phase 2).
- **Tools:** Python 3.12 venv, Terraform 1.17.2, AWS CLI 2.33.14, an SSH key pair at `~/.ssh/id_ed25519` (create with `ssh-keygen -t ed25519` if needed). Installed in Lab 2: ansible-core **2.21.6**, collections `amazon.aws` **12.1.0** and `community.docker` **5.4.0**, ansible-lint **26.11.0**.

## 3. Time estimate

**5–6 hours** (Lab 1: 45 min · Lab 2: 45 min · Lab 3: 1.5 h · Lab 4: 45 min · Incident: 1 h · Teardown: 15 min).

## 4. Cost estimate

| Resource | Billed while idle? | Unit price (assumption) | Expected use | Cost |
|---|---|---|---|---|
| 2 × EC2 `t3.micro` (Amazon Linux 2023) | yes | USD 0.0104/hour each | ≤ 6 h | ≤ USD 0.13 |
| 2 × 8 GiB gp3 root volumes | yes | USD 0.08/GB-month | ≤ 6 h | ≤ USD 0.01 |
| 2 × public IPv4 | yes | USD 0.005/hour each | ≤ 6 h | ≤ USD 0.06 |
| ECR data transfer to EC2 (same region) | — | no charge in the same region (assumption) | ~2 × 200 MB | USD 0 |

- **Pricing assumptions:** Region `us-east-1`; on-demand Linux; no free tier assumed (on accounts from 15 July 2025, `t3.micro` is free-tier eligible — see Phase 0 module 0.0). **Not re-checked** against https://aws.amazon.com/ec2/pricing/on-demand/, https://aws.amazon.com/ebs/pricing/, https://aws.amazon.com/vpc/pricing/ (checked: not yet).
- **Total if you follow teardown:** under **USD 0.25**.
- **If you skip teardown: ≈ USD 0.78/day** ((2 × 0.0104 + 2 × 0.005) × 24 = 0.74 + disks 16 × 0.08 / 30 = 0.04).

## 5. Concepts

### Why configuration management, if everything is a container?

Not everything is. Real estates still have VMs: legacy apps, bastion hosts, self-hosted CI runners, databases someone installed by hand, edge devices. Configuring them by SSH-ing in and typing commands produces **snowflakes** — servers that are each slightly different and that nobody can rebuild. **Ansible** describes the desired state of a host (packages, files, services) in YAML and applies it over SSH, **agentless**: nothing to install on the hosts except Python.
Source: https://docs.ansible.com/ansible/latest/getting_started/introduction.html

### Idempotency

Running the same playbook twice should change things **the first time only**. The second run reporting `changed=0` is your proof that the playbook describes a *state*, not a list of commands. A task that always reports `changed` (e.g. `command: docker run …`) is a smell: it can't tell you whether anything drifted.

### Inventory, dynamic

Hard-coding IPs in a file breaks the moment an instance is replaced. The **`amazon.aws.aws_ec2` inventory plugin** asks the EC2 API for instances by **tag** each time you run, and groups them (e.g. every instance with `role=orders-host` lands in group `role_orders_host`).
Source: https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html

### Templates and handlers

A **template** renders a config file from variables (Jinja2). A **handler** runs only when notified by a task that **changed** something — e.g. "restart the service" only if its unit file or env file actually changed. That's what makes a config rollout safe to re-run.

### `--check --diff`

Dry-run mode: Ansible reports what it *would* change and shows file diffs, without changing anything. On a fleet, it's how you **detect drift** — someone's manual edit shows up as a diff.

### Ansible vs Terraform

**Terraform** creates and destroys infrastructure (instances, security groups). **Ansible** configures what's *inside* a host. This module uses both: Terraform for the two hosts, Ansible for everything on them.

---

## 6. Labs

> **Region:** `us-east-1`. `export AWS_REGION=us-east-1 AWS_PROFILE=<your-admin-profile>`. Repo branch: `git switch -c phase3/ansible`. New directories: `infra/ops-hosts/` (Terraform) and `ansible/`.

### Lab 1 — Two hosts with Terraform

- **Region:** `us-east-1`
- **Task:** create `infra/ops-hosts/main.tf`:

```hcl
terraform {
  required_version = "~> 1.17.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.73" }
  }
  backend "s3" {
    key          = "labs/ops-hosts/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    # bucket supplied at init: -backend-config="bucket=tfstate-<account-id>-us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = { course = "aws-devops-platform", phase = "3", env = "ansible-lab", managed_by = "terraform" }
  }
}

variable "my_ip_cidr" { type = string } # your public IP as x.x.x.x/32

data "aws_vpc" "default" { default = true }
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_key_pair" "ops" {
  key_name   = "orders-ops"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

resource "aws_security_group" "ops" {
  name   = "orders-ops-hosts"
  vpc_id = data.aws_vpc.default.id
}
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ops.id
  cidr_ipv4         = var.my_ip_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.ops.id
  cidr_ipv4         = var.my_ip_cidr
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.ops.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_iam_role" "ops" {
  name = "orders-ops-host"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_instance_profile" "ops" {
  name = "orders-ops-host"
  role = aws_iam_role.ops.name
}

resource "aws_instance" "host" {
  count                  = 2
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ops.key_name
  vpc_security_group_ids = [aws_security_group.ops.id]
  iam_instance_profile   = aws_iam_instance_profile.ops.name
  metadata_options { http_tokens = "required" }
  tags = { Name = "orders-host-${count.index + 1}", role = "orders-host" }
}

output "ami_id"     { value = data.aws_ssm_parameter.al2023.value }
output "public_ips" { value = aws_instance.host[*].public_ip }
```

The AMI parameter always resolves to the current Amazon Linux 2023 image; the `ami_id` output records exactly which one you used. **Write it in your notes** — that's your pin. (Changing it later replaces both instances; that's expected.)

```bash
STATE_BUCKET="tfstate-$(aws sts get-caller-identity --query Account --output text)-us-east-1"
terraform -chdir=infra/ops-hosts init -backend-config="bucket=$STATE_BUCKET"
terraform -chdir=infra/ops-hosts apply -var "my_ip_cidr=$(curl -fsS https://checkip.amazonaws.com)/32"
```

- **Expected result:** `Apply complete!` with two `public_ips`.
- **Verification command:**

```bash
IP1="$(terraform -chdir=infra/ops-hosts output -json public_ips | python3 -c 'import sys,json;print(json.load(sys.stdin)[0])')"
ssh -o StrictHostKeyChecking=accept-new ec2-user@"$IP1" 'cat /etc/os-release | head -2; python3 --version'
# expect: Amazon Linux 2023 and a Python 3.x version
```

- **Teardown command:** `terraform -chdir=infra/ops-hosts destroy -var "my_ip_cidr=$(curl -fsS https://checkip.amazonaws.com)/32"` (at module end).
- **Cost note:** ≈ USD 0.033/hour for both hosts.

### Lab 2 — Install Ansible and build a dynamic inventory

- **Region:** `us-east-1`
- **Task:**

```bash
python3 -m venv .venv-ansible && source .venv-ansible/bin/activate
cat > ansible/requirements.txt <<'EOF'
ansible-core==2.21.6
ansible-lint==26.11.0
boto3==1.44.4
botocore==1.44.4
EOF
pip install -r ansible/requirements.txt

cat > ansible/requirements.yml <<'EOF'
collections:
  - name: amazon.aws
    version: "12.1.0"
  - name: community.docker
    version: "5.4.0"
EOF
ansible-galaxy collection install -r ansible/requirements.yml
```

`ansible/ansible.cfg`:

```ini
[defaults]
inventory = inventory/aws_ec2.yml
remote_user = ec2-user
private_key_file = ~/.ssh/id_ed25519
interpreter_python = auto_silent

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=accept-new
```

`ansible/inventory/aws_ec2.yml` (the file name **must** end in `aws_ec2.yml`):

```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  tag:env: ansible-lab
  instance-state-name: running
keyed_groups:
  - key: tags.role
    prefix: role
    separator: "_"
hostnames:
  - tag:Name
compose:
  ansible_host: public_ip_address
```

`accept-new` trusts a host's SSH key the first time and **refuses** if it later changes — safer than disabling host-key checking.

- **Expected result:** the inventory lists both hosts under one group.
- **Verification command:**

```bash
cd ansible
ansible-inventory --graph
# expect:  @role_orders_host: |--orders-host-1 |--orders-host-2   (group name: role_ + tag value with - → _)
ansible role_orders_host -m ansible.builtin.ping
# expect: two "pong" results
```

(TODO(verify): exact group name sanitisation for `orders-host` — if `ansible-inventory --graph` shows a different name, use that name in Labs 3–4. Also confirm ansible-core 2.21 still supports the Amazon Linux 2023 system Python (3.9) as a target: https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html. If not, install a newer `python3.x` package on the hosts in Lab 1's user data and set `ansible_python_interpreter`.)

- **Teardown command:** `deactivate` (the venv is local and free).
- **Cost note:** USD 0.

### Lab 3 — An idempotent playbook that runs the app

- **Region:** `us-east-1`
- **Task:** create the role `ansible/roles/orders_host/` and a playbook.

`ansible/group_vars/role_orders_host.yml`:

```yaml
aws_region: us-east-1
ecr_registry: "{{ lookup('ansible.builtin.env', 'ECR_REGISTRY') }}"
orders_image: "{{ ecr_registry }}/aws-devops-platform:{{ lookup('ansible.builtin.env', 'ORDERS_TAG') }}"
orders_env:
  APP_VERSION: "{{ lookup('ansible.builtin.env', 'ORDERS_TAG') }}"
  LOG_LEVEL: INFO
```

`ansible/roles/orders_host/tasks/main.yml`:

```yaml
- name: Docker is installed
  ansible.builtin.dnf:
    name: docker
    state: present

- name: Docker is running and enabled
  ansible.builtin.systemd_service:
    name: docker
    state: started
    enabled: true

- name: Config directory exists
  ansible.builtin.file:
    path: /etc/orders
    state: directory
    mode: "0750"

- name: App environment file
  ansible.builtin.template:
    src: orders.env.j2
    dest: /etc/orders/orders.env
    mode: "0640"
  notify: Restart orders

- name: Systemd unit
  ansible.builtin.template:
    src: orders.service.j2
    dest: /etc/systemd/system/orders.service
    mode: "0644"
  notify:
    - Reload systemd
    - Restart orders

- name: Orders service is running and enabled
  ansible.builtin.systemd_service:
    name: orders
    state: started
    enabled: true
```

`ansible/roles/orders_host/handlers/main.yml`:

```yaml
- name: Reload systemd
  ansible.builtin.systemd_service:
    daemon_reload: true

- name: Restart orders
  ansible.builtin.systemd_service:
    name: orders
    state: restarted
```

`ansible/roles/orders_host/templates/orders.env.j2`:

```jinja
# Managed by Ansible — manual edits will be overwritten
{% for k, v in orders_env.items() %}
{{ k }}={{ v }}
{% endfor %}
```

`ansible/roles/orders_host/templates/orders.service.j2`:

```ini
# Managed by Ansible — manual edits will be overwritten
[Unit]
Description=orders-api container
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=5
ExecStartPre=-/usr/bin/docker rm -f orders
ExecStartPre=/bin/sh -c 'aws ecr get-login-password --region {{ aws_region }} | docker login --username AWS --password-stdin {{ ecr_registry }}'
ExecStart=/usr/bin/docker run --rm --name orders -p 8000:8000 --env-file /etc/orders/orders.env {{ orders_image }}
ExecStop=/usr/bin/docker stop orders

[Install]
WantedBy=multi-user.target
```

`ansible/site.yml`:

```yaml
- name: Orders hosts
  hosts: role_orders_host
  become: true
  serial: 1            # one host at a time — the other keeps serving
  roles:
    - orders_host
```

Run it (Amazon Linux 2023 ships the AWS CLI, which the unit uses to log in to ECR with the instance role — no keys on the host):

```bash
cd ansible
export ECR_REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com"
export ORDERS_TAG="$(sed -E 's/.*"(.*)".*/\1/' ../infra/envs/dev/release.auto.tfvars)"
ansible-lint site.yml roles/
ansible-playbook site.yml
ansible-playbook site.yml          # second run
```

- **Expected result:** first run: several `changed`; **second run: `changed=0` on both hosts** in the `PLAY RECAP`. `ansible-lint` passes.
- **Verification command:**

```bash
for ip in $(terraform -chdir=../infra/ops-hosts output -json public_ips | python3 -c 'import sys,json;print(" ".join(json.load(sys.stdin)))'); do
  curl -fsS "http://$ip:8000/health"; echo; curl -fsS "http://$ip:8000/version"; echo
done
# expect for each host: {"status":"ok"} and {"version":"<ORDERS_TAG>"}
ansible-playbook site.yml | grep -E 'changed=[1-9]' && echo "NOT idempotent" || echo "idempotent"
# expect: idempotent
```

- **Teardown command:** section 9 (destroying the hosts removes everything Ansible configured).
- **Cost note:** USD 0 extra.

### Lab 4 — Roll a config change safely

- **Region:** `us-east-1`
- **Task:** change `LOG_LEVEL: INFO` → `LOG_LEVEL: WARNING` in `group_vars/role_orders_host.yml`.

```bash
ansible-playbook site.yml --check --diff       # preview: the env file diff on each host, nothing changed yet
ansible-playbook site.yml                      # apply, one host at a time (serial: 1)
```

- **Expected result:** `--check --diff` shows a `-LOG_LEVEL=INFO` / `+LOG_LEVEL=WARNING` diff per host and changes nothing. The real run changes the env file and runs **only** the `Restart orders` handler (not `Reload systemd` — the unit didn't change), host 1 then host 2.
- **Verification command:**

```bash
ansible role_orders_host -b -m ansible.builtin.command -a 'grep LOG_LEVEL /etc/orders/orders.env'
# expect: LOG_LEVEL=WARNING on both
ansible role_orders_host -b -m ansible.builtin.command -a 'systemctl show orders -p ActiveEnterTimestamp'
# expect: a timestamp from just now on both (restarted once)
ansible-playbook site.yml --check --diff | grep -c '^+' ; # expect: 0 (no further changes)
```

- **Teardown command:** none (keep `WARNING` or revert and re-run — your choice; commit whichever you keep).
- **Cost note:** USD 0 extra.

## 7. Debugging lab (incident)

- **Scenario — the page you get:**

> 🚨 **PagerDuty — 02:47 — `orders-host-2` health check FAILING (`:8000/health` connection refused, flapping).** `orders-host-1` is fine. In #ops at 02:10: *"host-2 was using a lot of memory, I capped the container. Should be fine now 👍"*. **You're on call: find what changed on host-2, restore it, and make sure it can't silently drift again.**

- **How to create the broken state** (from your `ansible/` directory, venv active, Lab 3 done):

```bash
export COURSE=<path to your clone of this course repo>
bash "$COURSE/phases/phase-3/05-ansible/labs/incident-drift/break.sh"
```

- **Symptom you will see:** `curl http://<host-2-ip>:8000/health` fails or succeeds only intermittently; host-1 is fine.
- **Your task:** diagnose **from your laptop with Ansible** (ad-hoc `command`/`shell` with `systemctl status orders`, `journalctl -u orders --since -30min`, `docker inspect`, and `ansible-playbook site.yml --check --diff --limit orders-host-2`). Fix it **with the playbook**, not by SSH-ing in. Write a 3-line incident note and one prevention.
- **Done when:**

```bash
ansible-playbook site.yml --check --diff --limit orders-host-2 | grep -E 'changed=0'   # no drift left
curl -fsS "http://<host-2-ip>:8000/health"                                            # {"status":"ok"}
ansible orders-host-2 -b -m ansible.builtin.command -a 'systemctl show orders -p NRestarts'
# expect: NRestarts stays the same if you run it twice a minute apart
```

- **Teardown:** none beyond section 9.

Diagnosis path: `solutions/incident.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Why would a team still need Ansible when the main app runs on ECS/EKS? Give two concrete cases.
2. Run the playbook twice and show the recap that proves idempotency. Why is `changed=0` on the second run the important result?
3. In Lab 4, why did `Restart orders` run but `Reload systemd` didn't?
4. What does `serial: 1` protect you from? What's the trade-off?
5. How does the dynamic inventory decide which hosts are in `role_orders_host`? What happens when an instance is replaced?
6. How does the container on each host pull from your private ECR without any access keys on the host?
7. Where does Terraform end and Ansible begin in this module, and why not do everything in one tool?

## 9. Teardown

```bash
export AWS_REGION=us-east-1
terraform -chdir=infra/ops-hosts destroy -var "my_ip_cidr=$(curl -fsS https://checkip.amazonaws.com)/32"
deactivate 2>/dev/null || true
```

**Confirm nothing is left:**

```bash
aws ec2 describe-instances --filters Name=tag:env,Values=ansible-lab Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[].Instances[].InstanceId' --output text         # expect: no output
aws ec2 describe-volumes --filters Name=tag:env,Values=ansible-lab --query 'Volumes[].VolumeId' --output text
                                                                        # expect: no output (root volumes inherit default tags — TODO(verify) volume tag propagation; if empty-but-unsure, also check describe-volumes --filters Name=status,Values=available)
aws ec2 describe-key-pairs --key-names orders-ops 2>&1 | grep -q InvalidKeyPair.NotFound && echo "key pair gone"
aws iam get-role --role-name orders-ops-host 2>&1 | grep -q NoSuchEntity && echo "role gone"
                                                                        # expect: key pair gone · role gone
```

Remove the hosts from your `~/.ssh/known_hosts` (`ssh-keygen -R <ip>` for each) — a new instance may later reuse an IP with a different host key, and `accept-new` will rightly refuse it.

Merge `phase3/ansible` with `ansible/` and `infra/ops-hosts/` (never commit `.venv-ansible/`).

## 10. Last verified

- **Date:** NOT YET VERIFIED — drafted 2026-11-17.
- **Verified by:** —
- **Region:** `us-east-1`
- **Versions:** ansible-core 2.21.6 (controller Python 3.12; 2.22 requires Python ≥ 3.13) · ansible-lint 26.11.0 · amazon.aws 12.1.0 · community.docker 5.4.0 · boto3/botocore 1.44.4 · Terraform 1.17.2 · AWS provider ~> 6.73 · AWS CLI 2.33.14 · AMI: Amazon Linux 2023 resolved via SSM (record the `ami_id` output)
- **Notes:** versions read from PyPI and Ansible Galaxy on 2026-11-17. No command run against AWS. Target-Python support and inventory group naming marked `TODO(verify)`.
