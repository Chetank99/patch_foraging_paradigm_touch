# Patch-Foraging Task: Paradigm code
### Optimized for vertical screen and touch

This directory contains the **codebase** for the patch-foraging behavioral paradigm in NIMH MonkeyLogic
---

## Core Files Overview

| File | Role | Description |
| :--- | :--- | :--- |
| **`frgfix.m`** | **Timing Script** | The master trial logic file. Handles state transitions, real-time travel animations, mouse sampling, reward calculations, and event marker delivery. |
| **`frg.txt`** | **Conditions File** | Defines the TaskObjects (Bushes, Box, Cars) and maps them to initial generator functions. |
| **`foraging_block_selection.m`** | **Block Progression** | Custom function controlling the progression sequence across Instruction, Practice, Forest, and Break blocks. |
| **`mycond2.m`** | **Condition Pools** | Initializes and shuffles the available condition list (travel distance indices) for each experimental block. |
| **`explore1.m` / `mexplore1.m`** | **Stimulus Generators** | Generates initial XY coordinates and returns pre-loaded image matrices for the visual stimuli. |

---

## How to Run a Session

1. Load the conditions file: **`frg.txt`**.
2. Verify that the timing script dropdown automatically selects **`frgfix.m`**.
3. Click **Run** or **Test** to initiate the session.

---

## ️ What can be configured

### In the code (`frgfix.m`)
Open `frgfix.m` to adjust core task parameters located cleanly at the top of the file:

```matlab
% --- TASK TUNING PARAMETERS ---
initialrew_base = 7;    % Baseline starting berry value for a fresh bush patch
dec_val = 0.5;          % Linear depletion rate subtracted per continuous harvest/pick
noise_sigma = 0.25;     % Gaussian standard deviation added to rewards

% --- TIMING & SOLENOID PARAMETERS ---
fix_reward = 75;        % Solenoid reward duration (ms) delivered for initial fixation
explore_Reward = 100;   % Solenoid reward duration (ms) delivered upon choosing travel
```

To modify **Travel Animations / Delay Times** per block, edit lines ~225-234:
```matlab
if TrialRecord.CurrentBlock==1
    delays=[3000,3000,3000,3000,3000,3000]; % Fast Forest travel duration (ms)
elseif TrialRecord.CurrentBlock==2
    delays=[9000,9000,9000,9000,9000,9000]; % Slow Forest travel duration (ms)
```

---

### Modifying Block Sequences (`foraging_block_selection.m`)
To change the order of tasks presented to the subject, edit the `block_sequence` array inside `foraging_block_selection.m`:
```matlab
% Block Mapping Key:
% 1 = Fast Forest
% 2 = Slow Forest
% 3 = Garage Break (5s mandatory rest)
% 4 = Interactive GUI Instructions
% 5 = Practice Trials

block_sequence = [4, 5, 1, 3, 2]; % Customize this sequence array
```

---

## Event Marker Dictionary

The task sends precise event codes directly to the data file (and LSL if we plan to use) to track behavioral latency and task milestones.

| Marker Code | Event Name | Functional Meaning |
| :---: | :--- | :--- |
| **`1`** | **Trial Start** | Delivered at the very first line of a trial execution. |
| **`3`** | **Fixation Start** | Subject cursor has successfully entered the center starting circle boundary. |
| **`4`** | **Fixation End** | Subject successfully held the cursor inside the circle for the full required jittered duration. |
| **`5`** | **Exploit Choice** | Subject hovered on the **Bush** to pick/stay in the current patch. |
| **`8`** | **Explore Choice** | Subject hovered on the **Box** to leave/travel to a new bush patch. |
| **`9`** | **Reward Display Start** | On-screen berry harvest text (e.g., `+6.50`) becomes visible. |
| **`6`** | **Trial End** | Delivered at the conclusion of feedback display or travel animation right before ITI. |

---

## A paper from Prof Arjun Ramakrishnan having a similar paradigm

This task paradigm is adapted from patch-foraging frameworks. For the full theoretical background, behavioral modeling approaches, and findings using variations of this task, you can check this outttt:

> **Barack, D. L., Ludwig, V. U., Parodi, F., Ahmed, N., Brannon, E. M., Ramakrishnan, A., & Platt, M. L.** (2024). *Attention deficits linked with proclivity to explore while foraging*. **Proceedings of the Royal Society B: Biological Sciences**, 291(2017), 20222584.  
> **DOI:** [10.1098/rspb.2022.2584](https://doi.org/10.1098/rspb.2022.2584)  
> **Article URL:** [Royal Society Publishing](https://royalsocietypublishing.org/rspb/article/291/2017/20222584/116431)

A version with shorter number of trials (which can be configured from the ML logic) [is available here](https://drive.google.com/file/d/1YZ5vm8QCidHAOpAiM7z-eqIpjk7OfIRx/view?usp=sharing)
