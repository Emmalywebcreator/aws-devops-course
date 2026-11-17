<!--
  Module template — copy to /phases/phase-N/<NN-module-slug>/module.md
  Every section below is REQUIRED (CLAUDE.md "Required module template").
  Replace every guidance comment and every <PLACEHOLDER>. Delete no section.
  Runnable labs go in ./labs/<lab-slug>/ ; self-check answers go in ./solutions/ (not linked from here).
-->

# Phase <N> · Module <NN> — <Module title>

## 1. Goal

<!-- ONE sentence: what the learner can DO at the end (observable), not what they "learn about".
     Example shape: "Deploy <X> to <Y> and prove it with <verification>." -->

<One-sentence goal>

## 2. Prerequisites

<!-- Link the EXACT earlier modules (relative paths). Never link a later module or phase.
     List tools that must already be installed, with the module that installed them.
     List accounts/access required (AWS account, GitHub, domain …). -->

- Modules: [<Phase N · Module NN — title>](../<NN-slug>/module.md)
- Tools installed: <tool> (from <module>)
- Access: <account / permission needed>

## 3. Time estimate

<!-- An honest RANGE for a target learner (see CLAUDE.md "Target learner"), including waiting time
     (certificate validation, deployments, alarms collecting data). Split by lab if > 3 hours. -->

<X–Y hours> (Lab 1: <a–b h>, Lab 2: <a–b h>, …)

## 4. Cost estimate

<!-- State EVERY pricing assumption. No figure without its assumptions (CLAUDE.md).
     Must include the "if you skip teardown" daily figure. Say "USD 0" explicitly for free modules. -->

| Resource | Billed while idle? | Unit price (assumption) | Expected use in this module | Cost |
|---|---|---|---|---|
| <resource> | <yes/no> | <USD x per hour/GB/month> | <hours / GB> | <USD> |

- **Pricing assumptions:** Region `<REGION>`; prices checked <YYYY-MM-DD> at <AWS pricing page URL>; <free tier assumed: NO>; <other assumptions>.
- **Total if you follow the teardown steps:** USD <x>
- **If you skip teardown: USD <x>/day**

## 5. Concepts

<!-- WHY before HOW: each tool/service is introduced by the problem it solves.
     Short (a few sentences each), then applied immediately in a lab.
     Prefer one worked example over five bullet points.
     Cite the official doc page for anything non-obvious (IAM evaluation, ECS task vs service, VPC routing). -->

### <Concept name>

- **Problem it solves:** <…>
- **How it works (plain English):** <…>
- **Applied in:** Lab <n>
- **Source:** <official doc URL>

## 6. Labs

<!-- One block per lab; runnable files live in ./labs/<lab-slug>/.
     Every lab states its Region explicitly. CLI-first; any Console step says "UI as of <YYYY-MM-DD>".
     No hardcoded account IDs/ARNs/credentials — derive them (aws sts get-caller-identity, outputs, lookups).
     Pin every version (images, actions, providers, Python deps). Never leave a NAT Gateway, idle EC2 or ECS service running. -->

### Lab <n> — <title>

- **Region:** `<REGION>`
- **Task:** <what the learner does, step by step>

```bash
# <commands>
```

- **Expected result:** <exact output / state the learner should see>
- **Verification command:**

```bash
# <command that proves it worked, and what its output must contain>
```

- **Teardown command:**

```bash
# <commands that remove everything this lab created>
```

- **Cost note:** <what this lab bills while it exists>

## 7. Debugging lab

<!-- A deliberately broken scenario. Give the learner the broken starting state and the symptom only.
     The fix and explanation go in ./solutions/, not here. Must include its own teardown. -->

- **Scenario:** <what is broken, described from the user's point of view>
- **How to create the broken state:**

```bash
# <commands>
```

- **Symptom you will see:** <exact error / behaviour>
- **Your task:** find the cause with <tools from this or earlier modules> and fix it.
- **Done when:** <verification command and expected output>
- **Teardown:** <commands>

## 8. Self-check

<!-- 5–8 questions or commands that PROVE mastery (not recall trivia).
     Answers live in ./solutions/self-check.md. -->

1. <question or command>
2. <…>
3. <…>
4. <…>
5. <…>

## 9. Teardown

<!-- Exact commands for EVERYTHING the module created, in dependency order, then a confirmation step
     that proves nothing billable is left (a command with its expected empty output). -->

```bash
# 1. <teardown commands, in order>
```

**Confirm nothing is left:**

```bash
# <command(s) — e.g. tagged-resource lookup — and the expected empty result>
```

## 10. Last verified

<!-- Filled in by a human who ran every command in this module. Unverified modules say "NOT YET VERIFIED". -->

- **Date:** <YYYY-MM-DD>
- **Verified by:** <name>
- **Region:** `<REGION>`
- **Versions:** OS <…> · AWS CLI <…> · Terraform <…> · AWS provider <…> · Docker <…> · Python <…> · GitHub Actions <action@version, …>
- **Notes:** <anything that differed from the text>
