#!/usr/bin/env bash
set -euo pipefail

MODEL=""
CODEX_CONFIG="${CODEX_HOME:-$HOME/.codex}/config.toml"
OPENCLAW_CONFIG="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
OPENCLAW_PROVIDER=""
BACKUP_DIR="/root/_Backups/cau-hinh-alt-codex"
DRY_RUN=0
ALL_AGENTS=0
UPDATE_CODEX=1
UPDATE_OPENCLAW=1

usage() {
  cat <<'EOF'
Usage: set_alt_model.sh --model MODEL [options]

Models: GPT-5.6-sol, GPT-5.6-terra, GPT-5.6-luna

Options:
  --all-agents              Update managed model overrides in agents.list
  --codex-only              Update only Codex config
  --openclaw-only           Update only OpenClaw config
  --codex-config PATH       Override Codex config path
  --openclaw-config PATH    Override OpenClaw config path
  --openclaw-provider ID   Override detected OpenClaw provider id
  --backup-dir PATH         Override backup directory
  --dry-run                 Show planned changes without writing
  -h, --help                Show this help
EOF
}

normalize_model() {
  local normalized
  normalized=$(printf '%s' "$1" | tr '[:upper:]_' '[:lower:] ' | sed -E 's/[[:space:]]+/-/g; s/-+/-/g; s/^-|-$//g')
  case "$normalized" in
    gpt-5.6-sol) printf '%s' 'GPT-5.6-sol' ;;
    gpt-5.6-terra) printf '%s' 'GPT-5.6-terra' ;;
    gpt-5.6-luna) printf '%s' 'GPT-5.6-luna' ;;
    *) return 1 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL=${2:-}; shift 2 ;;
    --all-agents) ALL_AGENTS=1; shift ;;
    --codex-only) UPDATE_OPENCLAW=0; shift ;;
    --openclaw-only) UPDATE_CODEX=0; shift ;;
    --codex-config) CODEX_CONFIG=${2:-}; shift 2 ;;
    --openclaw-config) OPENCLAW_CONFIG=${2:-}; shift 2 ;;
    --openclaw-provider) OPENCLAW_PROVIDER=${2:-}; shift 2 ;;
    --backup-dir) BACKUP_DIR=${2:-}; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$MODEL" ]]; then
  echo "Missing --model" >&2
  usage >&2
  exit 2
fi

if ! MODEL=$(normalize_model "$MODEL"); then
  echo "Unsupported model. Choose GPT-5.6-sol, GPT-5.6-terra, or GPT-5.6-luna." >&2
  exit 2
fi

if [[ $UPDATE_CODEX -eq 0 && $UPDATE_OPENCLAW -eq 0 ]]; then
  echo "Nothing to update." >&2
  exit 2
fi

STAMP=$(date -u +%Y%m%dT%H%M%SZ)

detect_openclaw_provider() {
  local primary provider candidates count provider_count

  if [[ -n "$OPENCLAW_PROVIDER" ]]; then
    if ! jq -e --arg provider "$OPENCLAW_PROVIDER" '.models.providers[$provider] != null' "$OPENCLAW_CONFIG" >/dev/null; then
      echo "OpenClaw provider not found: $OPENCLAW_PROVIDER" >&2
      return 1
    fi
    return 0
  fi

  primary=$(jq -r '.agents.defaults.model.primary // empty' "$OPENCLAW_CONFIG")
  if [[ "$primary" == */* ]]; then
    provider=${primary%%/*}
    if jq -e --arg provider "$provider" '.models.providers[$provider] != null' "$OPENCLAW_CONFIG" >/dev/null; then
      OPENCLAW_PROVIDER="$provider"
      return 0
    fi
  fi

  candidates=$(jq -r '
    .models.providers // {}
    | to_entries[]
    | select(any(.value.models[]?;
        .id == "codex" or
        .id == "GPT-5.6-sol" or
        .id == "GPT-5.6-terra" or
        .id == "GPT-5.6-luna"))
    | .key
  ' "$OPENCLAW_CONFIG")
  count=$(printf '%s\n' "$candidates" | sed '/^$/d' | wc -l)
  if [[ "$count" -eq 1 ]]; then
    OPENCLAW_PROVIDER=$(printf '%s\n' "$candidates" | sed '/^$/d')
    return 0
  fi

  provider_count=$(jq -r '(.models.providers // {}) | keys | length' "$OPENCLAW_CONFIG")
  if [[ "$provider_count" -eq 1 ]]; then
    OPENCLAW_PROVIDER=$(jq -r '(.models.providers // {}) | keys[0]' "$OPENCLAW_CONFIG")
    return 0
  fi

  echo "Cannot detect a unique OpenClaw provider. Use --openclaw-provider ID." >&2
  return 1
}

if [[ $UPDATE_OPENCLAW -eq 1 ]]; then
  command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
  [[ -f "$OPENCLAW_CONFIG" ]] || { echo "OpenClaw config not found: $OPENCLAW_CONFIG" >&2; exit 1; }
  detect_openclaw_provider
  OPENCLAW_MODEL="$OPENCLAW_PROVIDER/$MODEL"
fi

echo "Selected model: $MODEL"
[[ $UPDATE_CODEX -eq 1 ]] && echo "Codex config: $CODEX_CONFIG"
if [[ $UPDATE_OPENCLAW -eq 1 ]]; then
  echo "OpenClaw config: $OPENCLAW_CONFIG"
  echo "OpenClaw provider: $OPENCLAW_PROVIDER"
  echo "OpenClaw model ref: $OPENCLAW_MODEL"
fi
[[ $ALL_AGENTS -eq 1 ]] && echo "Agent overrides: managed models will be updated"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry-run: no files changed."
  exit 0
fi

mkdir -p "$BACKUP_DIR"

if [[ $UPDATE_CODEX -eq 1 ]]; then
  [[ -f "$CODEX_CONFIG" ]] || { echo "Codex config not found: $CODEX_CONFIG" >&2; exit 1; }
  CODEX_BACKUP="$BACKUP_DIR/codex-config.toml.$STAMP"
  cp -p "$CODEX_CONFIG" "$CODEX_BACKUP"
  MODEL_VALUE="$MODEL" perl -0pi -e 'my $m=$ENV{MODEL_VALUE}; s/^model\s*=\s*"[^"]*"/model = "$m"/m or die "Top-level model key not found\n"' "$CODEX_CONFIG"
fi

if [[ $UPDATE_OPENCLAW -eq 1 ]]; then
  OPENCLAW_BACKUP="$BACKUP_DIR/openclaw.json.$STAMP"
  cp -p "$OPENCLAW_CONFIG" "$OPENCLAW_BACKUP"
  TEMP_FILE=$(mktemp)
  trap 'rm -f "${TEMP_FILE:-}"' EXIT

  jq --arg model "$MODEL" --arg ref "$OPENCLAW_MODEL" --arg provider "$OPENCLAW_PROVIDER" --argjson allAgents "$ALL_AGENTS" '
    def managed($provider):
      . == ($provider + "/codex") or
      . == ($provider + "/GPT-5.6-sol") or
      . == ($provider + "/GPT-5.6-terra") or
      . == ($provider + "/GPT-5.6-luna");
    .models.providers[$provider].models = (
      (.models.providers[$provider].models // []) as $existing
      | ["GPT-5.6-sol", "GPT-5.6-terra", "GPT-5.6-luna"] as $managedIds
      | ($existing | map(select((.id as $id | $managedIds | index($id)) == null))) +
        ($managedIds | map({
          id: ., name: .,
          contextWindow: 128000,
          maxTokens: 4096
        }))
    )
    | .agents.defaults.model.primary = $ref
    | .agents.defaults.models = ((.agents.defaults.models // {}) + {($ref): {}})
    | if $allAgents == 1 then
        .agents.list = ((.agents.list // []) | map(
          if (.model? | type) == "string" and (.model | managed($provider)) then .model = $ref
          elif (.model?.primary? | type) == "string" and (.model.primary | managed($provider)) then .model.primary = $ref
          else . end
        ))
      else . end
  ' "$OPENCLAW_CONFIG" > "$TEMP_FILE"

  jq -e . "$TEMP_FILE" >/dev/null
  chmod --reference="$OPENCLAW_CONFIG" "$TEMP_FILE"
  chown --reference="$OPENCLAW_CONFIG" "$TEMP_FILE"
  mv "$TEMP_FILE" "$OPENCLAW_CONFIG"
  trap - EXIT

  if [[ "$OPENCLAW_CONFIG" == "$HOME/.openclaw/openclaw.json" ]] && command -v openclaw >/dev/null; then
    if ! openclaw config validate >/dev/null; then
      cp -p "$OPENCLAW_BACKUP" "$OPENCLAW_CONFIG"
      echo "OpenClaw validation failed; restored backup." >&2
      exit 1
    fi
  fi
fi

echo "Updated model to $MODEL."
[[ $UPDATE_CODEX -eq 1 ]] && echo "Codex backup: $CODEX_BACKUP"
[[ $UPDATE_OPENCLAW -eq 1 ]] && echo "OpenClaw backup: $OPENCLAW_BACKUP"
