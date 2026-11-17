# Rubric · Phase 0 exit gate, Gate C written explanations

> Grading rubric for Gate C in `assessments/gate-rules.md`. **Not linked from course navigation.**
> Score each explanation 0 / 1 / 2. Pass = total ≥ 10/12, **E1, E2, E3 each = 2**, none = 0.
> Self-graders: quote the sentence that earns each point you award.

**General scoring:** **2** = hits every *required* point, correctly, in the learner's own words. **1** = hits at least half the required points and states nothing dangerously wrong. **0** = misses most points, **or** states anything in the "automatic 0" column (a misconception that would cost money or compromise the account).

---

## E1 — Root user and how you sign in (P0-M07, P0-M08) — must score 2

| Required points | Automatic 0 if it says… |
|---|---|
| Root has unrestricted access to the account and can't be limited by IAM policies, so compromise = total loss (incl. billing). | "Root is fine if the password is strong." |
| Root has MFA and **no access keys**; used only for root-only tasks. | Using root access keys for the CLI. |
| Daily sign-in is through **IAM Identity Center** with a permission set. | Storing long-lived access keys in `~/.aws/credentials` as the normal approach. |
| CLI gets **temporary** credentials via `aws configure sso` / `aws sso login`; they expire, nothing long-lived is stored. | |

**Model answer (2/2):**
> The root user can do anything in the account, including closing it and changing billing, and no IAM policy can restrict it. If someone steals it, they own everything. So I turned on MFA for root, made sure it has no access keys, and only use it for the handful of tasks that require it. Day to day I sign in through IAM Identity Center as my own user, with a permission set that gives me what I need. For the CLI, I ran `aws configure sso` once to create a profile, and each session I run `aws sso login`. That opens the browser, I approve, and the CLI receives temporary credentials that expire on their own. There is no secret key sitting in a file on my laptop that could leak.

Sources: https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html · https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html

## E2 — What a budget does and doesn't do (P0-M08) — must score 2

| Required points | Automatic 0 if it says… |
|---|---|
| A budget **notifies** (email/SNS) when actual or forecasted spend crosses a threshold. | The budget stops, caps, or prevents charges. |
| It does **not** stop or delete resources; charges continue. | |
| Alerts are not instant — billing data lags (learner can say "can be delayed by hours"). | |
| A concrete first-10-minutes plan: sign in, find **what** is costing money (Bills / Cost Explorer by service & region), stop/delete it, verify it's gone, check for anything unexpected (possible compromise). | |

**Model answer (2/2):**
> My budget is USD 10/month with alerts at 80% actual and 100% forecasted, sent to my email. All it does is tell me. It won't stop or delete anything, so a forgotten resource keeps billing after the alert. Billing data is also delayed by hours, so by the time the email arrives I've already spent the money. If I get an alert, I sign in through SSO and open the bill to see which service and which region the charge is coming from. I delete that resource, then re-run the "is it gone" check for it. If I see a service or region I never used, I treat it as a possible compromise and lock down access first.

Note for graders: the "billing data lag" point — accept any correct statement that alerts aren't real-time; cite https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html. Mention of budget *actions* is a bonus, not required; claiming a plain alert stops resources is an automatic 0.

## E3 — Teardown proof (P0-M09) — must score 2

| Required points | Automatic 0 if it says… |
|---|---|
| Lists **every** resource the capstone created (matches the capstone module's resource list). | "I deleted it in the console so it's gone" with no check. |
| States a **deletion order** and why (dependents before what they depend on — e.g. empty a bucket before deleting it). | Claims of deletion with Gate B evidence that shows otherwise. |
| For each resource, names the **direct check** used and its "not found" result (Gate B G5). | |
| Mentions the tag-based sweep (G4) **and** local cleanup (G6). | |

**Model answer shape (2/2)** — exact content depends on the capstone module (not yet written):
> I created [resource list from capstone]. I deleted them in this order: [order], because [dependency reason, e.g. a bucket must be empty before it can be deleted]. To prove each was gone I ran [direct check per resource] and got [not-found output]. Then I ran the tag search for `course=aws-devops-platform`, `phase=0` in us-east-1, which returned `[]`, and the Docker label filters, which printed nothing. All of the output is pasted in my evidence file.

*Maintainer TODO: replace the bracketed shape with a concrete model answer once P0-M09 defines its resources.*

## E4 — DNS vs connection failure (P0-M03)

| Required points | Automatic 0 if it says… |
|---|---|
| `(6)`: hostname couldn't be resolved to an IP; no connection was attempted. | Both errors mean "the server is down". |
| First check for (6): spelling of the hostname / DNS lookup (`dig`, `nslookup`, `getent hosts`). | |
| `(7)`: name resolved, but the TCP connection to that IP:port failed (nothing listening, refused, or blocked). | |
| First check for (7): is the service running/listening on that port, and is a firewall/security rule blocking it (e.g. `nc -vz host port`, `ss -ltn` on the server). | |

Source: https://curl.se/libcurl/c/libcurl-errors.html

## E5 — Leaked secret response (P0-M04)

| Required points | Automatic 0 if it says… |
|---|---|
| **First** revoke/rotate the secret at its source (e.g. deactivate the AWS access key). | Deleting the file / making the repo private is enough. |
| Deleting the file leaves it in Git history and in any clone/fork/scrape already made. | Rewriting history first and never rotating. |
| Then remove it from history (e.g. `git filter-repo` per GitHub Docs) and force-push; tell collaborators to re-clone. | |
| Prevention: `.gitignore` for `.env`-style files / secret scanning / never put secrets in the repo. | |

Source: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

## E6 — Why pin versions (P0-M05, P0-M06)

| Required points | Automatic 0 if it says… |
|---|---|
| Pinning makes builds **reproducible**: same inputs → same result today and in a month. | Pinning is "for performance" or "required by Docker". |
| Unpinned (`:latest`, `pip install requests`) can change underneath you without any code change. | |
| One **concrete** breakage example (e.g. a new base image drops a package / bumps Python and the app fails to start; a library major version removes a function). | |
| Upgrades become deliberate: change the pin, test, commit. | |

Source: https://docs.docker.com/build/building/best-practices/

---

*Status: drafted 2026-11-17; citations not yet checked by the `qa` agent; E3 model answer pending P0-M09.*
