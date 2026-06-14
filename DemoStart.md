# Demo Start Guide

This document captures the intended modernization demo flow for the legacy sample.

## Flow
1. Use GHCP to reverse-engineer the main user flows and save the findings to a local markdown artifact in this repo (ignored by Git).
2. Turn those documented use cases into Playwright tests so the UI is protected against regressions.
3. Run the GitHub Modernization Agent only after the UI baseline is documented and tested.
4. In the alternative path, show the modernization outcome because the Playwright tests cover the UI surface that should remain stable.

## Why this order
- It gives the demo a clear, low-cost starting point.
- It documents the user experience before code changes begin.
- It helps reduce modernization risk by validating the UI surface up front.

## Notes
- Keep the first pass lightweight and focused on the highest-value user flows.
- Save any draft findings to a local ignored markdown file in this repo.
- Do not change application code in this phase.
