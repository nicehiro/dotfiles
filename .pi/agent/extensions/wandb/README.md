# pi-wandb

[Weights & Biases](https://wandb.ai/) integration for [pi](https://github.com/badlogic/pi-mono).

Registers three tools the LLM can call to inspect experiment runs, metrics, and training curves.

## Install

```bash
pi install npm:pi-wandb
```

## Configuration

Set your W&B API key in your shell:

```bash
export WANDB_API_KEY=your-api-key
```

Optionally set a custom API endpoint:

```bash
export WANDB_BASE_URL=https://api.wandb.ai  # default
```

## Tools

### wandb_runs

List runs from a project with optional filters and sorting.

| Parameter | Description |
|---|---|
| `entity` | W&B entity (username or team) |
| `project` | Project name |
| `filters` | JSON filter string, e.g. `'{"state":"finished"}'` or `'{"tags":{"$in":["baseline"]}}'` |
| `order` | Sort order, e.g. `+created_at`, `-summary_metrics.loss` |
| `max_results` | Max runs to return (default 20, max 100) |

### wandb_run

Get full details of a specific run including config, summary metrics, notes, and system metrics.

| Parameter | Description |
|---|---|
| `entity` | W&B entity |
| `project` | Project name |
| `run_id` | Run ID (the short alphanumeric ID, not display name) |

### wandb_history

Get sampled metric history (training curves) for a run.

| Parameter | Description |
|---|---|
| `entity` | W&B entity |
| `project` | Project name |
| `run_id` | Run ID |
| `samples` | Number of sampled datapoints (default 500, max 10000) |

## Examples

- *"List my recent runs in project 'diffusion-policy'"*
- *"Show me the config and final metrics for run abc123"*
- *"Get the loss curve for that run"*
- *"Compare finished runs tagged 'baseline' in myteam/robotics"*
