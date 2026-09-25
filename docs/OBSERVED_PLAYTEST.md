# Observed internal playtest

Use the current `0.2.0-playtest.1` Windows ZIP and keep its build manifest with the session notes. This protocol is ready for local testing; it does not require Steamworks. Automated results are recorded separately in `RELEASE_EXECUTION_STATUS.md`.

## First ten minutes — five new players

Ask each player to extract the ZIP, launch the game and start a realm. Give only this introduction: “Build a settlement, survive the nights, and compete for the Shard.” Do not show the build-order section of the playtest guide before this part. Ask the player to think aloud. Help only if they cannot launch or a bug prevents further play; record any help.

Start the real-time clock when the player can interact. Record the seed, quality setting, resolution, GPU, build-manifest revision, and any pause or speed changes. Capture these observations without supplying the answer:

| Moment | Record |
| --- | --- |
| First useful construction | Real-time minute; building; whether it completed |
| First observed delivery | What the player thinks the settler is carrying and where it goes |
| First stall | Player's explanation; attempted remedy; help required |
| Five-minute check | Can they explain a delivery and start useful construction? |
| Ten-minute check | What is their next objective, and how do they plan to reach it? |
| End of opening | Most confusing moment; whether they want to continue |

Opening gate: at least four of five players meet both timed checks without coaching. This small pilot is a decision aid, not a statistical estimate. Keep failed attempts and assisted sessions in the results.

## Three complete matches

After the opening exercise, allow the playtest guide. Use seeds 260821, 424242 and 717171 across three human sessions. Record real time separately from simulation time. Do not prepare resources or skip phases. Include at least one natural victory and one defeat whose cause the player can explain; add sessions if the first three do not cover both.

Record food stability, first raid, first Outpost, first Lumen extension, rival contest, first assault, Binding interruption, final result, and every point where the player cannot identify a next action. Ask whether the outcome felt understandable and whether another match sounds appealing. Do not interpret an automated bot victory as a human completion.

During one session, save with a delivery in progress, exit, relaunch and Continue. During another, repeat in a raid or during Binding. Note any missing cargo, changed orders or lost progress. If a bug occurs, stop changing the realm and use **SAVE FEEDBACK REPORT**; record the last action and expected outcome with the local report.

## Session record

Copy this block into a separate note for each participant; use a participant code rather than personal details.

```text
Participant code / date:
Build revision / executable SHA256:
Seed / resolution / quality / GPU:
Prior experience with settlement games:
First construction / first delivery (real minutes):
Five-minute check (pass, fail or assisted; evidence):
Ten-minute check (pass, fail or assisted; evidence):
Food / first raid / Outpost / Lumen / assault / Binding milestones:
Result / real duration / simulation duration / pause and speed use:
Confusing moments and interventions:
Save/relaunch result:
Feedback bundle path and reproduction steps:
Would play again? Why?
```

Do not recruit or message participants automatically. The next release decision uses these observations together with package stability, minimum-hardware testing and the deferred Steamworks work.
