# Tiled Classroom Spin-Off Plan

## Purpose

This is not the same goal as Tiled v1.

The classroom direction should be treated as a focused spin-off or framework layer built from proven parts of Tiled, not as extra scope to cram into the first public party-game release.

## Why This Direction Makes Sense

The current core has natural educational potential:
- reveal-based pacing supports guided inference
- short rounds suit group participation
- question packs can be tailored to topics or age groups
- mobile controllers can support low-friction classroom participation

## Product Framing

The likely opportunity is not “party game with a school mode”.
The likely opportunity is “a lightweight reveal-game framework for classrooms, quizzes, and guided discussion”.

That framing matters because classroom use implies different priorities:
- reliability over novelty
- easy customisation over broad content variety
- moderation and teacher control over party-style spontaneity
- clear setup and repeatability over playful chaos

## Core Classroom Requirements

### Must have
- simple content authoring and import format
- small default pack for demonstration
- easy branding/customisation
- deterministic round setup
- obvious controls for starting, skipping, and resetting rounds
- family-safe and school-safe defaults

### Likely needed
- teacher-facing host controls
- pack/category filtering by topic or age range
- support for shorter sessions and lesson timing
- clearer results/history for recap discussion
- lower reading-load variants where possible

### Not assumed yet
- LMS integration
- accounts
- cloud content platform
- deep analytics
- heavy admin tooling

## Technical Reuse Hypothesis

Potentially reusable from Tiled:
- host/controller architecture
- reveal board presentation
- answer validation systems
- room/session handling
- export and local hosting model

Potentially divergent:
- scoring importance
- tone and presentation
- moderation flow
- content schema fields
- teacher control surfaces

## Suggested Development Path

### Step 1: Prove reuse boundaries
After Tiled v1, identify which systems are truly generic and which are party-game-specific.

### Step 2: Define the classroom user
Choose a concrete first user before building features.
Examples:
- primary teacher running a class quiz
- small-group intervention activity
- home educator using custom topic packs

### Step 3: Create a minimal classroom pack format
Keep it simple:
- prompt
- answer
- acceptable alternatives
- category/topic
- optional difficulty or age tag

### Step 4: Build a constrained pilot
A pilot should focus on:
- one classroom use case
- one or two lesson structures
- simple custom content workflow
- low support burden

## Design Principles


## Ownership & Data Sovereignty

Schools have been burned by platforms that own their data, lock in their workflows, and change pricing or terms mid-contract. This product should be something a school can own outright.

### Non-negotiable constraints
- **No accounts required.** The tool works without signing in to anything.
- **No data leaves the room.** All session data stays local. Nothing is transmitted to external services.
- **No subscription cliff.** The tool does not stop working if a payment lapses or a service is retired.
- **No platform dependency.** No Google Workspace integration, no Microsoft 365 integration, no "helpful" cloud sync that creates a lock-in relationship.

### What this looks like in practice
A teacher should be able to:
- copy the folder to a USB drive
- take it to a school with no internet connection
- plug it into a Windows or Linux machine
- run a full lesson

That is the ownership test. If it fails that test, the architecture is wrong.

### Why this matters more here than in the party game
Adults choosing a party game make their own informed choices about software. Schools do not always have that luxury — institutional IT decisions often lock in students and teachers to platforms they did not choose. This product should not be another one of those.

The goal is software that belongs to its users, not software that users belong to.

## Risks

- trying to serve schools and party players with one UI may weaken both
- classroom needs may demand more control and less spontaneity than the current product assumes
- “framework” thinking can trigger premature abstraction before usage patterns are known

## Exit Criteria

A classroom spin-off is worth active development when:
- Tiled v1 has proven the base architecture in real use
- one classroom user profile has been selected clearly
- the content format can be customised without developer intervention
- the control flow works in a time-boxed session
- educator feedback points to repeated value, not just theoretical value

## Near-Term Rule

Do not fold classroom work into Tiled v1 unless it directly improves the core architecture or content tooling needed for the party game anyway.
