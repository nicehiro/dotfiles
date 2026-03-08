#!/usr/bin/env bash
# org-roam helper: query, create, link, and open notes via emacsclient
set -euo pipefail

ROAM_DIR="${ORG_ROAM_DIR:-$HOME/Documents/roam}"

usage() {
  cat <<'EOF'
Usage: roam.sh <command> [args...]

Commands:
  search <query>             Search nodes by title (SQL LIKE, case-insensitive)
  search-full <query>        Full-text grep across all .org files
  get-node <id>              Get node title and file by ID
  get-backlinks <id>         List nodes that link TO this node
  get-forwardlinks <id>      List nodes this node links TO
  orphans [limit]            List nodes with no incoming links (default: all)
  all-nodes                  List all nodes (id, title, file)
  paper-nodes                List nodes that have cite refs
  create-note <title>        Create a concept note, prints file path
  create-paper-note <citekey> <title> [filetags]
                             Create a paper note for a citekey
  add-link <source-file> <target-id> <target-title>
                             Append an org-roam link to end of source file
  add-link-under <source-file> <target-id> <target-title> <heading>
                             Insert an org-roam link under a heading
  suggest-links <id>         Find potentially related notes (by title keywords)
  open <file>                Open file in Emacs and raise frame
  db-sync                    Sync the org-roam database
EOF
}

# Escape a shell string for safe inclusion in a double-quoted Elisp string
elisp_escape() {
  local s="${1-}"
  s=${s//\\/\\\\}
  s=${s//"/\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

# Run elisp via emacsclient, strip surrounding quotes, convert \n to real newlines
eeval() {
  emacsclient --eval "$1" 2>/dev/null | sed 's/^"//;s/"$//' | sed 's/\\n/\n/g' | sed 's/\\"/"/g'
}

# Same but keep raw output (for UUIDs etc)
eeval_raw() {
  emacsclient --eval "$1" 2>/dev/null | tr -d '"'
}

# Update org-roam DB for a specific file
db_update_file() {
  local file
  file=$(elisp_escape "$1")
  eeval_raw "(org-roam-db-update-file \"${file}\")" > /dev/null
}

cmd_search() {
  local pattern
  pattern=$(elisp_escape "$1")
  eeval "(mapconcat (lambda (row) (format \"%s | %s | %s\" (nth 0 row) (nth 1 row) (nth 2 row))) (org-roam-db-query [:select [id title file] :from nodes :where (like title (quote \"%${pattern}%\"))]) \"\n\")"
}

cmd_search_full() {
  grep -ril --include="*.org" "$1" "$ROAM_DIR" 2>/dev/null | while read -r f; do
    local title id
    title=$(grep -m1 '^#+title:' "$f" | sed 's/^#+title: *//')
    id=$(grep -m1 '^:ID:' "$f" | sed 's/^:ID: *//')
    echo "$id | $title | $f"
  done
}

cmd_get_node() {
  local id
  id=$(elisp_escape "$1")
  eeval "(let ((row (car (org-roam-db-query [:select [id title file] :from nodes :where (= id \"${id}\")] )))) (when row (format \"%s | %s | %s\" (nth 0 row) (nth 1 row) (nth 2 row))))"
}

cmd_get_backlinks() {
  local id
  id=$(elisp_escape "$1")
  eeval "(mapconcat (lambda (row) (format \"%s | %s | %s\" (nth 0 row) (nth 1 row) (nth 2 row))) (org-roam-db-query [:select [nodes:id nodes:title nodes:file] :from links :inner-join nodes :on (= links:source nodes:id) :where (and (= links:dest \"${id}\") (= links:type \"id\"))]) \"\n\")"
}

cmd_get_forwardlinks() {
  local id
  id=$(elisp_escape "$1")
  eeval "(mapconcat (lambda (row) (format \"%s | %s | %s\" (nth 0 row) (nth 1 row) (nth 2 row))) (org-roam-db-query [:select [nodes:id nodes:title nodes:file] :from links :inner-join nodes :on (= links:dest nodes:id) :where (and (= links:source \"${id}\") (= links:type \"id\"))]) \"\n\")"
}

cmd_orphans() {
  local limit="${1:-9999}"
  eeval "(mapconcat (lambda (row) (format \"%s | %s | %s\" (nth 0 row) (nth 1 row) (nth 2 row))) (org-roam-db-query [:select [id title file] :from nodes :where (not-in id [:select :distinct [dest] :from links :where (= type \"id\")]) :limit ${limit}]) \"\n\")"
}

cmd_all_nodes() {
  eeval "(mapconcat (lambda (row) (format \"%s | %s | %s\" (nth 0 row) (nth 1 row) (nth 2 row))) (org-roam-db-query [:select [id title file] :from nodes]) \"\n\")"
}

cmd_paper_nodes() {
  eeval "(mapconcat (lambda (row) (format \"%s | %s | %s\" (nth 0 row) (nth 1 row) (nth 2 row))) (org-roam-db-query [:select [nodes:id nodes:title nodes:file] :from nodes :inner-join refs :on (= nodes:id refs:node-id) :where (= refs:type \"cite\")]) \"\n\")"
}

cmd_create_note() {
  local title="$1"
  local slug
  slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//')
  local timestamp
  timestamp=$(date +%Y%m%d%H%M%S)
  local filepath="${ROAM_DIR}/${timestamp}-${slug}.org"
  local uuid
  uuid=$(eeval_raw '(org-id-new)')

  cat > "$filepath" <<EOF
:PROPERTIES:
:ID:       ${uuid}
:END:
#+title: ${title}

EOF

  db_update_file "$filepath"
  echo "$filepath"
}

cmd_create_paper_note() {
  local citekey="$1"
  local title="$2"
  local filetags="${3:-}"
  local filepath="${ROAM_DIR}/${citekey}.org"

  if [[ -f "$filepath" ]]; then
    echo "EXISTS:$filepath"
    return 0
  fi

  local uuid
  uuid=$(eeval_raw '(org-id-new)')

  {
    echo ":PROPERTIES:"
    echo ":ID:       ${uuid}"
    echo ":ROAM_REFS: @${citekey}"
    echo ":END:"
    echo "#+title: ${title}"
    [[ -n "$filetags" ]] && echo "#+filetags: ${filetags}"
    echo ""
  } > "$filepath"

  db_update_file "$filepath"
  echo "$filepath"
}

cmd_add_link() {
  local source_file="$1" target_id="$2" target_title="$3"

  if grep -qF "id:${target_id}" "$source_file" 2>/dev/null; then
    echo "ALREADY_LINKED"
    return 0
  fi

  printf '\n- [[id:%s][%s]]\n' "$target_id" "$target_title" >> "$source_file"
  db_update_file "$source_file"
  echo "LINKED"
}

cmd_add_link_under() {
  local source_file="$1" target_id="$2" target_title="$3" heading="$4"

  if grep -qF "id:${target_id}" "$source_file" 2>/dev/null; then
    echo "ALREADY_LINKED"
    return 0
  fi

  python3 - "$source_file" "$heading" "$target_id" "$target_title" <<'PYEOF'
import sys
filepath, heading, tid, ttitle = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
link = f"- [[id:{tid}][{ttitle}]]"
with open(filepath) as f:
    lines = f.readlines()
inserted = False
for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith('*') and heading in stripped:
        level = len(stripped) - len(stripped.lstrip('*'))
        j = i + 1
        while j < len(lines):
            s = lines[j].strip()
            if s.startswith('*') and (len(s) - len(s.lstrip('*'))) <= level:
                break
            j += 1
        lines.insert(j, link + '\n')
        inserted = True
        break
if not inserted:
    lines.append(f"\n* {heading}\n{link}\n")
with open(filepath, 'w') as f:
    f.writelines(lines)
PYEOF

  db_update_file "$source_file"
  echo "LINKED"
}

cmd_suggest_links() {
  local id="$1"
  local escaped_id
  escaped_id=$(elisp_escape "$id")

  local title
  title=$(eeval_raw "(car (car (org-roam-db-query [:select [title] :from nodes :where (= id \"${escaped_id}\")])))")

  if [[ -z "$title" || "$title" == "nil" ]]; then
    echo "Node not found: $id" >&2
    return 1
  fi

  # Get node's file for content-based matching
  local node_file
  node_file=$(eeval_raw "(car (car (org-roam-db-query [:select [file] :from nodes :where (= id \"${escaped_id}\")])))")

  # Get existing links to exclude
  local -a existing_ids=()
  while IFS= read -r eid; do
    [[ -n "$eid" ]] && existing_ids+=("$eid")
  done < <(eeval "(mapconcat (function car) (org-roam-db-query [:select [dest] :from links :where (and (= source \"${escaped_id}\") (= type \"id\"))]) \"\n\")")

  # Extract keywords from title (skip stopwords)
  local -a keywords=()
  for w in $(echo "$title" | tr '[:upper:]' '[:lower:]' | grep -oE '[a-z]{3,}' | sort -u); do
    case "$w" in
      the|and|for|with|from|that|this|are|was|were|has|have|not|but|can|will|its|via|over|into|also|use|used|using) continue ;;
    esac
    keywords+=("$w")
  done

  # Also extract keywords from file content (filetags, headings)
  if [[ -f "$node_file" ]]; then
    while IFS= read -r w; do
      [[ -n "$w" ]] && keywords+=("$w")
    done < <(grep -oE ':[a-zA-Z-]+:' "$node_file" 2>/dev/null | tr -d ':' | tr '[:upper:]' '[:lower:]' | grep -E '.{3,}' | sort -u)
  fi

  declare -A scores
  declare -A node_titles
  declare -A node_files

  for w in "${keywords[@]}"; do
    local raw
    local escaped_w
    escaped_w=$(elisp_escape "$w")
    raw=$(eeval "(mapconcat (lambda (row) (format \"%s\t%s\t%s\" (nth 0 row) (nth 1 row) (nth 2 row))) (org-roam-db-query [:select [id title file] :from nodes :where (like title (quote \"%${escaped_w}%\"))]) \"\n\")")
    while IFS=$'\t' read -r nid ntitle nfile; do
      [[ -z "$nid" || "$nid" == "$id" ]] && continue
      # Skip already linked
      local skip=false
      for eid in "${existing_ids[@]}"; do
        [[ "$eid" == "$nid" ]] && { skip=true; break; }
      done
      $skip && continue
      scores[$nid]=$(( ${scores[$nid]:-0} + 1 ))
      node_titles[$nid]="$ntitle"
      node_files[$nid]="$nfile"
    done <<< "$raw"
  done

  for nid in "${!scores[@]}"; do
    echo "${scores[$nid]} | ${nid} | ${node_titles[$nid]} | ${node_files[$nid]}"
  done | sort -t'|' -k1 -rn | head -20
}

cmd_open() {
  local file
  file=$(elisp_escape "$1")
  eeval_raw "(progn (find-file \"${file}\") (raise-frame))" > /dev/null
  echo "Opened in Emacs: $1"
}

cmd_db_sync() {
  eeval_raw '(org-roam-db-sync)' > /dev/null
  echo "org-roam DB synced"
}

# --- main ---
[[ $# -lt 1 ]] && { usage; exit 1; }
cmd="$1"; shift

case "$cmd" in
  search)           cmd_search "$1" ;;
  search-full)      cmd_search_full "$1" ;;
  get-node)         cmd_get_node "$1" ;;
  get-backlinks)    cmd_get_backlinks "$1" ;;
  get-forwardlinks) cmd_get_forwardlinks "$1" ;;
  orphans)          cmd_orphans "${1:-}" ;;
  all-nodes)        cmd_all_nodes ;;
  paper-nodes)      cmd_paper_nodes ;;
  create-note)      cmd_create_note "$1" ;;
  create-paper-note) cmd_create_paper_note "$@" ;;
  add-link)         cmd_add_link "$@" ;;
  add-link-under)   cmd_add_link_under "$@" ;;
  suggest-links)    cmd_suggest_links "$1" ;;
  open)             cmd_open "$1" ;;
  db-sync)          cmd_db_sync ;;
  *)                usage; exit 1 ;;
esac
