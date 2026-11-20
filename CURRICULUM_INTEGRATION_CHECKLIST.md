# Curriculum Integration Checklist

**Project:** AWS DevOps Engineering Course  
**Purpose:** Integrate all Phase 1 and Phase 2 learning modules from the original 28-week curriculum into the expanded course website before beginning the learning journey.

**Status legend**
- [ ] Missing / not verified
- [x] Verified complete
- [~] Partially integrated
- [>] Intentionally relocated (document the destination)

> Do not mark a module complete merely because a link exists. Verify its content, exercises, assessment, navigation and accessibility.

---

## 0. Integration rules

- [ ] Keep the expanded repository as the primary course platform.
- [ ] Preserve the original 28-week curriculum as a reference until migration is verified.
- [ ] Avoid silently deleting or shortening original learning objectives, explanations, labs, code, exercises or assessment requirements.
- [ ] Document intentional changes or relocations.
- [ ] Verify each module locally in the browser and on the deployed website.
- [ ] Confirm that progress tracking, navigation and assessment gates behave correctly.

## 1. Source inventory

- [ ] Review the original 28-week course and list all modules, lessons, labs, exercises, projects and gate requirements.
- [ ] Review the expanded repository's module directories and navigation.
- [ ] Review the existing `MAPPING.md` migration plan.
- [ ] Review the current Phase 0 content to avoid duplication.
- [ ] Review Phase 3 content and its dependencies.
- [ ] Identify every source item that has no destination in the expanded website.
- [ ] Identify any new-platform content that is not present in the original and document it.

## 2. Phase 1 — CI/CD and AWS application deployment

For each module below, verify that its full lesson content, practical work, assessment, navigation and any required solution/reference are integrated.

- [ ] **1.1 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **1.2 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **1.3 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **1.4 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **1.5 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **1.6 — Phase 1 exit gate (verify exact title and criteria)**
  - [ ] Gate instructions
  - [ ] Required evidence and rubric
  - [ ] Failure/remediation guidance
  - [ ] Reassessment process
  - [ ] Gate status correctly controls progression

## 3. Phase 2 — Infrastructure as Code and environments

Verify the exact titles and sequence against the source curriculum and existing `MAPPING.md`.

- [ ] **2.1 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.2 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.3 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.4 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.5 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.6 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.7 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  - [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.8 — [Confirm exact title against source curriculum]**
  - [ ] Learning objectives and explanations
  -  [ ] Practical/lab and instructions
  - [ ] Assessment or evidence requirements
  - [ ] Navigation and progress tracking
- [ ] **2.9 — Phase 2 exit gate (verify exact title and criteria)**
  - [ ] Gate instructions
  - [ ] Required evidence and rubric
  - [ ] Failure/remediation guidance
  - [ ] Reassessment process
  - [ ] Gate status correctly controls progression

## 4. Content migration audit — every lesson

For each source lesson, use this checklist before marking it integrated.

- [ ] The module has the correct title, number and sequence.
- [ ] All original learning objectives are preserved or deliberately revised.
- [ ] Explanations are complete and beginner-accessible.
- [ ] Technical terms are explained when first introduced.
- [ ] Examples, diagrams, code and commands are migrated and checked.
- [ ] Labs include prerequisites, steps, expected outcomes and verification.
- [ ] Troubleshooting/failure exercises are included where applicable.
- [ ] Exercises or knowledge checks are present.
- [ ] Assessment criteria and evidence requirements are clear.
- [ ] Solutions or instructor/reference material are handled appropriately.
- [ ] AWS cost, safety and cleanup instructions are included where relevant.
- [ ] Links, downloads and code references work.
- [ ] Previous/next lesson links work.
- [ ] The module is reachable from the main course navigation.
- [ ] Completion/progress tracking behaves as intended.

## 5. Assessment and gate integration

- [ ] Phase 1 gate is linked to the correct Phase 1 modules.
- [ ] Phase 2 gate is linked to the correct Phase 2 modules.
- [ ] Gate requirements reflect the skills taught in the modules.
- [ ] Gate tasks test independent practical competence, not only recall.
- [ ] Time limits account for environmental delays and accessibility.
- [ ] Evidence submission/verification instructions are clear.
- [ ] Failed gates provide actionable remediation.
- [ ] Learners can reassess after remediation.
- [ ] Passing a gate unlocks the intended next stage.
- [ ] Gate status and learner progress persist correctly.
- [ ] No gate is accidentally bypassed or blocks the learner without explanation.

## 6. Website navigation and functionality

- [ ] Every Phase 1 module is listed and reachable.
- [ ] Every Phase 2 module is listed and reachable.
- [ ] Phase and module labels are consistent across the platform.
- [ ] Previous/next navigation follows the intended learning order.
- [ ] Breadcrumbs or other navigation aids work, if present.
- [ ] Progress indicators reflect actual completion.
- [ ] Links do not point to missing pages or incorrect paths.
- [ ] No placeholder or empty module pages remain unintentionally.
- [ ] Mobile layout is usable.
- [ ] Browser refresh does not unexpectedly lose saved progress.
- [ ] A new learner can navigate the course without assistance.

## 7. Technical verification

- [ ] Run the project's documented build command successfully.
- [ ] Resolve build errors and warnings that affect functionality.
- [ ] Check console errors and failed requests.
- [ ] Check internal links and routes.
- [ ] Check code blocks, diagrams, images and downloadable resources.
- [ ] Check deployed pages against local pages.
- [ ] Confirm the legacy/original curriculum remains available as intended.
- [ ] Confirm that no sensitive credentials, tokens or personal data are exposed.

## 8. AWS safety and cost review

- [ ] All AWS exercises identify potentially billable resources.
- [ ] Cost estimates or cost-awareness notes are reviewed.
- [ ] Budget alerts and account safety guidance are linked where needed.
- [ ] IAM instructions follow least privilege where practical.
- [ ] No learner is instructed to expose credentials or secrets.
- [ ] Cleanup instructions are provided for every lab that creates resources.
- [ ] Cleanup verification is scoped to course-created resources where possible.
- [ ] Cleanup instructions and commands are tested.
- [ ] Lab prerequisites and region assumptions are stated.

## 9. Final acceptance — Phase 1 and Phase 2 integration

- [ ] Every source module has a documented destination.
- [ ] Every source learning objective is accounted for.
- [ ] All Phase 1 modules are integrated and verified.
- [ ] All Phase 2 modules are integrated and verified.
- [ ] Both exit gates are integrated and tested.
- [ ] Phase 1 and Phase 2 navigation is complete.
- [ ] Progress tracking is tested.
- [ ] Website build succeeds.
- [ ] Deployed website is reviewed.
- [ ] No unintended placeholders, missing modules or broken links remain.
- [ ] Integration changes are committed to Git.
- [ ] Integration audit is dated and recorded.

**Integration status:** Not yet verified

**Audit date:** ____________________

**Notes / unresolved issues:**
