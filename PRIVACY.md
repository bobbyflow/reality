# Privacy contract

Reality tracks the minimum evidence required to reconstruct time accurately.

## Collected locally

- Foreground application bundle identifier and display name
- Start/end timestamps
- Idle, locked, asleep, excluded, and unavailable states
- User-created categories, intentions, corrections, and reviews

## Disabled by default

- Focused window titles
- Browser domains
- AI-generated coaching

Enabling focused titles requires macOS Accessibility permission. Browser domains require a separate opt-in browser extension and are not inferred from page titles.

## Never collected

- Keystrokes
- Clipboard contents
- Screenshots or screen recordings
- Message, email, or document contents
- Passwords or authentication tokens

## Storage and retention

- Data is stored in the user's Application Support directory.
- Raw samples have a short configurable retention period; default: 14 days.
- Derived activity blocks remain until deleted by the user.
- Excluded activity stores only an `excluded` interval, never identifying metadata.
- Any future network feature must be opt-in, documented, and disabled by default.

## User controls

Users can pause collection, exclude applications/domains, correct classifications, export data, delete a day/range, or permanently delete all data.
