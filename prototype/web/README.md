# Reality web prototype

Interaction prototype for the Reality local-first macOS tracker.

This is not the native collector. Manual capture and local browser persistence work; automatic macOS activity collection is intentionally represented as unavailable until the native implementation is healthy.

The prototype starts empty and never presents sample activity as real user history.

## Run

```bash
npm install
npm test
npm run dev
```

## Data

Manual prototype entries use browser local storage. Do not use the prototype for sensitive production data. The native app will replace this with GRDB/SQLite under Application Support.
