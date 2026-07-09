# Reality engineering contract

- Privacy and truthful state are product requirements, not polish.
- Never add screenshots, keystroke capture, clipboard capture, or hidden monitoring.
- Never commit personal activity data, databases, exports, logs, credentials, or signing material.
- Automatic tracking must never appear active unless the native collector is running and healthy.
- Keep collection, segmentation, classification, persistence, and presentation as separate boundaries.
- Use deterministic local rules in the critical path. AI may consume redacted aggregates only when explicitly enabled.
- Use TDD for time segmentation, idle/away handling, exclusions, deletion, and aggregation.
- Run the narrowest relevant test plus the full verification script before claiming completion.
