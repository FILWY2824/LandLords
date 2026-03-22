# Configuration

## Shared env template

Use [`landlords.env.example`](../landlords.env.example) as the checked-in template
for local setup.

Recommended workflow:

1. Copy `landlords.env.example` to `landlords.env`.
2. Change only the values that are different on your machine.
3. Run [`run_backend_with_onnx.ps1`](../run_backend_with_onnx.ps1) and
   [`run_frontend_web_23000.ps1`](../run_frontend_web_23000.ps1).

Both scripts load `landlords.env` automatically when it exists. The live
`landlords.env` file is ignored by git, while the example template stays in the repo
for contributors.

## Important keys

- `LANDLORDS_PORT` / `LANDLORDS_WS_PORT`: backend TCP and WebSocket ports
- `LANDLORDS_WEB_PORT`: local web bridge port
- `LANDLORDS_DATA_DIR`: repo-relative runtime data directory
- `LANDLORDS_DOUZERO_ONNX_DIR_EASY`: DouZero ADP model directory
- `LANDLORDS_DOUZERO_ONNX_DIR_NORMAL`: DouZero SL model directory
- `LANDLORDS_DOUZERO_ONNX_DIR_HARD`: DouZero WP model directory
- `LANDLORDS_HINT_BOT_DIFFICULTY`: hint button difficulty, defaults to `hard`
- `LANDLORDS_MANAGED_BOT_DIFFICULTY`: managed/autoplay difficulty, defaults to `hard`

## Persistence layout

Runtime data now uses a mixed layout under `LANDLORDS_DATA_DIR`:

- `users/<user_id>/profile.v2`: per-user private record
- `index/users_by_account.v1`: global account lookup index
- `social/friend_requests/<request_id>.v1`: friend request records
- `social/inboxes/<user_id>.v1`: per-user friend-request index

Legacy flat files `users.db` and `friend_requests.db` are obsolete and are no longer
read by the server.

The per-user files reduce write conflicts, and the global files stay limited to
lookup/index data instead of storing every field for every user in one place.
