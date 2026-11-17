# Solution · 3.5 self-check

> Not linked from the module.

1. Any two: legacy apps that can't be containerised; bastion/jump hosts; self-hosted CI runners; databases or brokers on VMs; on-prem or edge machines; base OS hardening of EKS self-managed nodes or golden AMIs.
2. `ansible-playbook site.yml` twice → second `PLAY RECAP` shows `changed=0` for both hosts. It proves the playbook describes a desired *state* that the hosts already match — so any future `changed` means real drift or a real change, not noise.
3. Handlers run only when notified by a task that reported `changed`. Only the env-file template changed, and it notifies `Restart orders`; the unit template didn't change, so `Reload systemd` was never notified.
4. A bad change taking down every host at once: with `serial: 1`, host 1 is updated (and could fail the play) while host 2 still serves. Trade-off: slower rollouts on big fleets (use a percentage like `serial: "25%"`).
5. The `aws_ec2` plugin queries EC2 for running instances tagged `env=ansible-lab` and builds a group per `role` tag value. A replaced instance has the same tags, so it appears automatically (new IP, same group) the next time Ansible runs.
6. Each host has an IAM **instance profile** with `AmazonEC2ContainerRegistryReadOnly`. The unit's `ExecStartPre` runs `aws ecr get-login-password`, which uses the instance role's temporary credentials from the instance metadata service (IMDSv2 required).
7. Terraform creates/destroys the infrastructure (key pair, security group, IAM role, instances) and tracks it in state; Ansible configures inside the hosts (packages, files, services). Terraform isn't good at ongoing in-host configuration; Ansible doesn't track cloud resources' lifecycle in state.
