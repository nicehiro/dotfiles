---
name: mission-control
description: "Multi-agent mission orchestration system. Use when managing complex tasks that span multiple agents, threads, or require coordination. Alma acts as project manager, tracking progress, detecting stalls, and driving missions to completion."
allowed-tools:
  - Bash
  - Task
  - TaskOutput
  - Read
  - Write
---

# Mission Control Skill

Alma's mission orchestration system. You are the **project manager** — you break down goals into tasks, assign them to agents, monitor progress, and drive everything to completion.

## Core Concepts

- **Mission**: A high-level goal (e.g., "Fix the login bug and deploy", "Research competitors and write report")
- **Agent**: A Task tool subagent or external process working on part of a mission
- **Comms**: Inter-agent message bus — agents post updates, you read and coordinate
- **Heartbeat**: You check all active missions every heartbeat tick

## When to Use

- User gives you a complex, multi-step goal
- A task naturally breaks into parallel workstreams
- You need to coordinate multiple agents/threads
- You want to track long-running work across sessions

## CLI Reference

### Mission Management

```bash
# Create a new mission
alma mission create "Fix login bug and deploy to production" \
  --goals "1. Identify root cause" "2. Write fix" "3. Add tests" "4. Deploy"

# List all missions
alma mission list                    # active missions
alma mission list --all              # include completed/cancelled

# View mission details
alma mission status <missionId>

# Update mission progress
alma mission progress <missionId> --goal 1 --status done --note "Found the bug in auth.ts"
alma mission progress <missionId> --goal 2 --status in-progress

# Assign an agent to a mission
alma mission assign <missionId> --agent <taskId> --role "Fix the auth bug" 

# Complete or cancel a mission
alma mission complete <missionId> --summary "Bug fixed and deployed"
alma mission cancel <missionId> --reason "No longer needed"

# Add a note/log to mission
alma mission log <missionId> "Discovered the root cause is in token refresh"
```

### Inter-Agent Communication (Comms)

```bash
# Send a message to a mission channel (all agents on this mission can see it)
alma comms send <missionId> "Found the bug — it's in auth.ts line 42"

# Send a direct message to a specific agent
alma comms dm <agentTaskId> "Please also check the refresh token logic"

# Read messages from a mission channel
alma comms read <missionId>              # last 20 messages
alma comms read <missionId> --limit 50   # more messages

# Read direct messages for current agent
alma comms inbox

# Broadcast to all active missions
alma comms broadcast "Going offline for maintenance in 5 min"
```

## Mission Lifecycle

### 1. Create Mission
When the user gives you a complex goal:
```bash
alma mission create "Build the new feature X" \
  --goals "Research existing codebase" "Design API" "Implement backend" "Write tests" "Deploy"
```

### 2. Break Down & Assign
Spawn agents for parallel work:
```
# In your response, use Task tool to create agents:
Task(subagent_type="coder", description="Implement backend API", prompt="...", run_in_background=true)
Task(subagent_type="Explore", description="Research codebase", prompt="...", run_in_background=true)

# Then register them with the mission:
alma mission assign <missionId> --agent <taskId1> --role "Backend implementation"
alma mission assign <missionId> --agent <taskId2> --role "Codebase research"
```

### 3. Monitor & Drive (Heartbeat)
Every heartbeat, you see mission status. Your job:
- Check which agents completed, which are stuck
- Read comms for updates from agents
- Unblock stuck agents by providing context or reassigning
- Update progress when goals are met
- Report significant milestones to the user

### 4. Coordinate
When an agent needs info from another:
```bash
# Agent A posts finding to mission channel
alma comms send <missionId> "The API uses JWT, not sessions. Agent B should update their approach."

# You (Alma) read this and relay to Agent B
alma comms dm <agentB-taskId> "FYI: API uses JWT. Adjust your implementation accordingly."
```

### 5. Complete
When all goals are done:
```bash
alma mission complete <missionId> --summary "Feature X shipped: API + tests + deployed to staging"
```

## Agent Instructions

When spawning agents for a mission, include these instructions in their prompt:

```
You are working on Mission: [missionId] — "[mission description]"
Your role: [specific role]
Goals assigned to you: [list]

COMMUNICATION: Post updates to the mission channel:
  alma comms send [missionId] "your update here"
Post when: you complete a goal, hit a blocker, need info from another agent, or find something unexpected.

CONTEXT from other agents:
  alma comms read [missionId]
Read the channel before starting to see what others have found.
```

## Heartbeat Integration

During heartbeat, you'll see a MISSION REVIEW section like:

```
MISSION REVIEW:
🟢 Mission "Fix login bug" (m-abc123) — 3/4 goals done
   Agent task-xyz (coder): completed ✅ — "Fixed auth.ts"  
   Agent task-uvw (coder): running 8min — "Writing tests"
   Unread comms: 2 messages

🟡 Mission "Research competitors" (m-def456) — 1/3 goals done
   Agent task-rst (Explore): stuck? running 25min
   Unread comms: 0 messages
   ⚠️ Agent may be stuck — investigate with TaskOutput
```

Your response should:
1. Check stuck agents (TaskOutput)
2. Read unread comms
3. Update progress if goals completed
4. Report to user if milestone reached
5. Reassign or unstick blocked agents

## File Structure

```
~/.config/alma/missions/
├── missions.json          # All missions
├── comms/
│   ├── <missionId>.jsonl  # Mission channel messages
│   └── dm/
│       └── <taskId>.jsonl # Direct messages to agents
```

## Tips

- **Don't over-engineer missions** — simple tasks don't need a mission. Use missions for genuinely multi-step, multi-agent work.
- **Keep comms concise** — agents should post brief updates, not essays.
- **Proactive > reactive** — don't wait for the user to ask. If a mission is done, tell them. If it's stuck, investigate.
- **2-3 agents max per mission** — more than that gets chaotic. Break into sub-missions if needed.
- **Include context in agent prompts** — agents start fresh. Give them everything they need upfront.
