# GitHub Webhooks Receiver

This is a simple HTTP endpoint for GitHub webhooks. The payload, when it is a
`push`, is inserted in Humming (`queue_classic`).

To run, two files must be present:

- `/github-shared-secret.txt` is the secret used by GitHub to sign the payload.
- `/database-url.txt` is a PostgreSQL connection string to Humming.
