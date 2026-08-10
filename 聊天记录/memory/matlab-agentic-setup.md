---
name: matlab-agentic-setup
description: This project has MATLAB MCP server + Agentic Toolkit skills installed; how to run MATLAB code
metadata: 
  node_type: memory
  type: project
  originSessionId: b55baf50-1264-4893-8002-701b9fb7be88
  modified: 2026-08-09T01:41:10.197Z
---

The "Beam Traing" project is a MATLAB near-field beam-training research codebase (rainbow / TTD / beam-split; lots of `.m` files, no Simulink). MATLAB **R2024b** is installed at `D:\Program Files\MATLAB\R2024b` (on PATH).

On 2026-08-09 the MATLAB agentic tooling was installed so Claude Code can run/test/analyze MATLAB directly:
- **MATLAB MCP Server** v0.11.3 (from github.com/matlab/matlab-mcp-server) at `C:\Users\CWH\.matlab\agentic-toolkits\bin\matlab-mcp-server.exe`, registered in Claude Code as MCP server `matlab` (user scope, in `~/.claude.json`) with `--matlab-root D:\Program Files\MATLAB\R2024b`. Provides tools: `evaluate_matlab_code`, `run_matlab_file`, `run_matlab_test_file`, `check_matlab_code`, `detect_matlab_toolboxes`.
- **Skill plugins** from marketplace `matlab-agentic-toolkit` (user scope): `matlab-core`, `signal-processing`, `wireless-communications`.
- MATLAB companion toolbox `MATLABMCPServerToolbox.mltbx` installed → `shareMATLABSession()` available so the agent can attach to an already-open MATLAB session (session mode defaults to `auto`).

These MCP tools/plugins only load in a **fresh** Claude Code session (not the one where they were installed). Telemetry to MathWorks is ON by default. Test file present: `limited_ttd_extension\tests\LimitedTTDBeamTest.m`.
