#!/usr/bin/env bash
#
# apple-mail.sh — Query Apple Mail's local storage
# Adapted from mitsuhiko/agent-stuff, commit 122e2994adddb113c04764c5697217dae120fcc6.
# Modified for read-only SQL, validated arguments, portable paths, and lossless attachment copies.
# SPDX-License-Identifier: Apache-2.0
#
# Usage:
#   apple-mail.sh search [OPTIONS]        Search emails
#   apple-mail.sh read <MESSAGE_ID>       Read raw .emlx email
#   apple-mail.sh attachment <MSG_ID> [ATTACHMENT_NAME]  Extract attachment(s) to tempdir
#   apple-mail.sh mailboxes               List all mailboxes
#   apple-mail.sh info <MESSAGE_ID>       Show message metadata
#
# Search options:
#   --from <addr>       Filter by sender address (substring match)
#   --to <addr>         Filter by recipient address (substring match)
#   --subject <text>    Filter by subject (substring match)
#   --body <text>       Filter by body/summary text (substring match)
#   --mailbox <name>    Filter by mailbox URL (substring match)
#   --after <date>      Emails after date (YYYY-MM-DD)
#   --before <date>     Emails before date (YYYY-MM-DD)
#   --unread            Only unread messages
#   --flagged           Only flagged messages
#   --has-attachment     Only messages with attachments
#   --limit <n>         Max results (default: 20)
#
# Examples:
#   apple-mail.sh search --from "peter@" --subject "dinner" --limit 5
#   apple-mail.sh search --after 2026-02-01 --has-attachment
#   apple-mail.sh read 783663
#   apple-mail.sh attachment 783660
#   apple-mail.sh attachment 783660 "Rechnung_908105840226.pdf"
#
set -euo pipefail
umask 077

MAIL_DIR="$HOME/Library/Mail"
MAIL_VERSION_DIR=""
ENVELOPE_DB=""
ATTACHMENT_TMP=""

fail() {
    echo "Error: $*" >&2
    exit 1
}

cleanup() {
    if [[ -n "$ATTACHMENT_TMP" ]]; then
        rm -rf "$ATTACHMENT_TMP"
    fi
}
trap cleanup EXIT

validate_id() {
    [[ "$1" =~ ^[1-9][0-9]*$ && ${#1} -le 19 ]] || fail "Message ID must be a positive integer."
}

require_value() {
    [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Option $1 requires a value."
}

# Find the latest Mail version directory
find_mail_dir() {
    [[ -d "$MAIL_DIR" && -r "$MAIL_DIR" && -x "$MAIL_DIR" ]] ||
        fail "Cannot access $MAIL_DIR. Set up Apple Mail and, if macOS denies access, grant Full Disk Access to the terminal or host running Pi."
    local candidate version latest=-1
    for candidate in "$MAIL_DIR"/V[0-9]*; do
        [[ -d "$candidate" ]] || continue
        version=${candidate##*/V}
        [[ "$version" =~ ^[0-9]+$ && ${#version} -le 9 ]] || continue
        if (( 10#$version > latest )); then
            latest=$((10#$version))
            MAIL_VERSION_DIR="$candidate"
        fi
    done
    if [[ -z "$MAIL_VERSION_DIR" ]]; then
        echo "Error: No accessible Apple Mail version directory in $MAIL_DIR. Check Full Disk Access for the terminal or host running Pi." >&2
        exit 1
    fi
    ENVELOPE_DB="$MAIL_VERSION_DIR/MailData/Envelope Index"
    if [[ ! -f "$ENVELOPE_DB" || ! -r "$ENVELOPE_DB" ]]; then
        echo "Error: Envelope Index missing or unreadable at $ENVELOPE_DB. Check Apple Mail setup and Full Disk Access." >&2
        exit 1
    fi
}

# Run a sqlite3 query against the envelope index
sql() {
    sqlite3 -init /dev/null -readonly -bail -cmd '.timeout 5000' -header -separator '|' "$ENVELOPE_DB" "$1"
}

sql_noheader() {
    sqlite3 -init /dev/null -readonly -bail -cmd '.timeout 5000' -separator '|' "$ENVELOPE_DB" "$1"
}

# Convert YYYY-MM-DD to unix timestamp
date_to_ts() {
    [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail "Date must use YYYY-MM-DD: $1"
    local timestamp normalized
    if command -v gdate &>/dev/null; then
        timestamp=$(gdate -d "$1 00:00:00" '+%s' 2>/dev/null) || fail "Invalid date: $1"
        normalized=$(gdate -d "@$timestamp" '+%Y-%m-%d')
    else
        timestamp=$(date -j -f '%Y-%m-%d %H:%M:%S' "$1 00:00:00" '+%s' 2>/dev/null) || fail "Invalid date: $1"
        normalized=$(date -r "$timestamp" '+%Y-%m-%d')
    fi
    [[ "$normalized" == "$1" ]] || fail "Invalid date: $1"
    printf '%s\n' "$timestamp"
}

# Compute the Data subdirectory path for a message ROWID
# Pattern: take digits except last 3, reverse them, use as path components
# e.g., 783663 -> "783" reversed -> "3/8/7"
# e.g., 79782 -> "79" reversed -> "9/7"
msg_data_subpath() {
    local id="$1"
    if [[ ${#id} -le 3 ]]; then
        # Message ID is 3 digits or fewer, no subdirectory
        echo ""
        return
    fi
    local prefix="${id:0:${#id}-3}"
    local reversed=""
    local i
    for (( i=${#prefix}-1; i>=0; i-- )); do
        reversed+="${prefix:$i:1}/"
    done
    # Remove trailing slash
    echo "${reversed%/}"
}

# Find the .emlx file for a message ROWID
find_emlx() {
    local msg_id="$1"
    local subpath
    subpath=$(msg_data_subpath "$msg_id")

    # Search across all account/mbox directories for this message
    local search_path
    if [[ -n "$subpath" ]]; then
        search_path="$subpath/Messages"
    else
        search_path="Messages"
    fi

    local found
    found=$(find "$MAIL_VERSION_DIR" -type f -path "*/Data/$search_path/${msg_id}.emlx" -print -quit) || return
    if [[ -n "$found" ]]; then
        printf '%s\n' "$found"
    else
        find "$MAIL_VERSION_DIR" -type f -path "*/Data/$search_path/${msg_id}.partial.emlx" -print -quit
    fi
}

# Find attachment directory for a message
find_attachment_dir() {
    local msg_id="$1"
    local subpath
    subpath=$(msg_data_subpath "$msg_id")

    local search_path
    if [[ -n "$subpath" ]]; then
        search_path="$subpath/Attachments/$msg_id"
    else
        search_path="Attachments/$msg_id"
    fi

    find "$MAIL_VERSION_DIR" -type d -path "*/Data/$search_path" -print -quit
}

# --- Commands ---

cmd_mailboxes() {
    sql "SELECT mb.ROWID, mb.url, mb.total_count, mb.unread_count
         FROM mailboxes mb
         ORDER BY mb.url"
}

cmd_search() {
    local from_filter="" to_filter="" subject_filter="" body_filter=""
    local mailbox_filter="" after_ts="" before_ts=""
    local unread="" flagged="" has_attachment=""
    local limit=20
    local quote="'"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from|--to|--subject|--body|--mailbox|--after|--before|--limit) require_value "$@" ;;
        esac
        case "$1" in
            --from)     from_filter="$2"; shift 2 ;;
            --to)       to_filter="$2"; shift 2 ;;
            --subject)  subject_filter="$2"; shift 2 ;;
            --body)     body_filter="$2"; shift 2 ;;
            --mailbox)  mailbox_filter="$2"; shift 2 ;;
            --after)    after_ts=$(date_to_ts "$2"); shift 2 ;;
            --before)   before_ts=$(date_to_ts "$2"); shift 2 ;;
            --unread)   unread=1; shift ;;
            --flagged)  flagged=1; shift ;;
            --has-attachment) has_attachment=1; shift ;;
            --limit)    limit="$2"; shift 2 ;;
            *) echo "Unknown option: $1" >&2; exit 1 ;;
        esac
    done

    [[ "$limit" =~ ^[1-9][0-9]*$ && ${#limit} -le 4 ]] || fail "Limit must be an integer from 1 to 1000."
    (( limit <= 1000 )) || fail "Limit must be an integer from 1 to 1000."

    local where_clauses=()

    if [[ -n "$from_filter" ]]; then
        # Escape single quotes
        local esc_from="${from_filter//$quote/$quote$quote}"
        where_clauses+=("a.address LIKE '%${esc_from}%'")
    fi

    if [[ -n "$to_filter" ]]; then
        local esc_to="${to_filter//$quote/$quote$quote}"
        where_clauses+=("m.ROWID IN (SELECT r.message FROM recipients r JOIN addresses ra ON r.address = ra.ROWID WHERE ra.address LIKE '%${esc_to}%')")
    fi

    if [[ -n "$subject_filter" ]]; then
        local esc_subj="${subject_filter//$quote/$quote$quote}"
        where_clauses+=("s.subject LIKE '%${esc_subj}%'")
    fi

    if [[ -n "$body_filter" ]]; then
        local esc_body="${body_filter//$quote/$quote$quote}"
        where_clauses+=("su.summary LIKE '%${esc_body}%'")
    fi

    if [[ -n "$mailbox_filter" ]]; then
        local esc_mb="${mailbox_filter//$quote/$quote$quote}"
        where_clauses+=("mb.url LIKE '%${esc_mb}%'")
    fi

    if [[ -n "$after_ts" ]]; then
        where_clauses+=("m.date_received >= $after_ts")
    fi

    if [[ -n "$before_ts" ]]; then
        where_clauses+=("m.date_received < $before_ts")
    fi

    if [[ -n "$unread" ]]; then
        where_clauses+=("m.read = 0")
    fi

    if [[ -n "$flagged" ]]; then
        where_clauses+=("m.flagged = 1")
    fi

    if [[ -n "$has_attachment" ]]; then
        where_clauses+=("m.ROWID IN (SELECT DISTINCT att.message FROM attachments att)")
    fi

    # Always exclude deleted
    where_clauses+=("m.deleted = 0")

    local where_sql=""
    if [[ ${#where_clauses[@]} -gt 0 ]]; then
        local joined=""
        for clause in "${where_clauses[@]}"; do
            if [[ -n "$joined" ]]; then
                joined="$joined AND $clause"
            else
                joined="$clause"
            fi
        done
        where_sql="WHERE $joined"
    fi

    # Build the query — use LEFT JOIN for summary/body since not all messages have it
    local query="
        SELECT m.ROWID AS id,
               a.address AS sender,
               a.comment AS sender_name,
               s.subject,
               datetime(m.date_received, 'unixepoch', 'localtime') AS received,
               CASE WHEN m.read = 1 THEN '' ELSE 'UNREAD' END AS status,
               CASE WHEN m.flagged = 1 THEN 'FLAGGED' ELSE '' END AS flagged,
               REPLACE(REPLACE(mb.url, 'imap://', ''), 'local://', '') AS mailbox,
               (SELECT COUNT(*) FROM attachments att WHERE att.message = m.ROWID) AS attachments
        FROM messages m
        JOIN addresses a ON m.sender = a.ROWID
        JOIN subjects s ON m.subject = s.ROWID
        JOIN mailboxes mb ON m.mailbox = mb.ROWID
        LEFT JOIN summaries su ON m.summary = su.ROWID
        $where_sql
        ORDER BY m.date_received DESC
        LIMIT $limit
    "

    sql "$query"
}

cmd_info() {
    local msg_id="$1"

    echo "=== Message $msg_id ==="
    echo ""

    # Basic info
    sql "SELECT m.ROWID AS id,
                a.address AS sender,
                a.comment AS sender_name,
                s.subject,
                datetime(m.date_received, 'unixepoch', 'localtime') AS received,
                datetime(m.date_sent, 'unixepoch', 'localtime') AS sent,
                m.size,
                CASE WHEN m.read = 1 THEN 'read' ELSE 'unread' END AS status,
                CASE WHEN m.flagged = 1 THEN 'flagged' ELSE '' END AS flagged,
                mb.url AS mailbox
         FROM messages m
         JOIN addresses a ON m.sender = a.ROWID
         JOIN subjects s ON m.subject = s.ROWID
         JOIN mailboxes mb ON m.mailbox = mb.ROWID
         WHERE m.ROWID = $msg_id"

    echo ""
    echo "--- Recipients ---"
    sql "SELECT a.address, a.comment,
                CASE r.type WHEN 0 THEN 'to' WHEN 1 THEN 'cc' WHEN 2 THEN 'bcc' END AS type
         FROM recipients r
         JOIN addresses a ON r.address = a.ROWID
         WHERE r.message = $msg_id
         ORDER BY r.type, r.position"

    echo ""
    echo "--- Attachments ---"
    sql "SELECT att.attachment_id, att.name
         FROM attachments att
         WHERE att.message = $msg_id"

    echo ""
    echo "--- Summary/Preview ---"
    sql_noheader "SELECT su.summary FROM messages m JOIN summaries su ON m.summary = su.ROWID WHERE m.ROWID = $msg_id" | sed -n '1,20p'
}

cmd_read() {
    local msg_id="$1"
    local emlx_path
    emlx_path=$(find_emlx "$msg_id")

    if [[ -z "$emlx_path" ]]; then
        echo "Error: Could not find .emlx file for message $msg_id" >&2
        echo "The email body may not have been downloaded (check if it exists as .partial.emlx)" >&2
        exit 1
    fi

    local basename
    basename=$(basename "$emlx_path")
    if [[ "$basename" == *.partial.emlx ]]; then
        echo "Note: This is a partial download (headers only, body not fully cached locally)" >&2
        echo "" >&2
    fi

    # .emlx format: first line is byte count, then the RFC822 message, then Apple plist
    # Read the byte count from the first line, then output that many bytes
    local header byte_count file_size end_offset
    IFS= read -r header < "$emlx_path" || fail "Invalid .emlx header for message $msg_id."
    byte_count=${header%$'\r'}
    [[ "$byte_count" =~ ^[0-9]+$ && ${#byte_count} -le 9 ]] || fail "Invalid .emlx byte count for message $msg_id."
    byte_count=$((10#$byte_count))
    end_offset=$((${#header} + 1 + byte_count))
    file_size=$(wc -c < "$emlx_path")
    (( file_size >= end_offset )) || fail "Truncated .emlx file for message $msg_id."
    head -c "$end_offset" "$emlx_path" | tail -c "$byte_count"
}

cmd_attachment() {
    local msg_id="$1"
    local filter_name="${2:-}"

    local att_dir
    att_dir=$(find_attachment_dir "$msg_id")

    if [[ -z "$att_dir" ]]; then
        echo "Error: No attachment directory found for message $msg_id" >&2
        echo "" >&2
        echo "Available attachments in database:" >&2
        sql "SELECT att.attachment_id, att.name FROM attachments att WHERE att.message = $msg_id" >&2
        exit 1
    fi

    local tmpdir
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/mail-attachments-${msg_id}.XXXXXX")
    ATTACHMENT_TMP="$tmpdir"
    local file_list="$tmpdir/.files"
    find "$att_dir" -type f -print0 > "$file_list"

    local found=0
    # Walk the attachment directory: structure is att_dir/attachment_id/filename
    while IFS= read -r -d '' file; do
        local name relative target
        name=${file##*/}
        if [[ -n "$filter_name" && "$name" != "$filter_name" ]]; then
            continue
        fi
        relative=${file#"$att_dir"/}
        target="$tmpdir/files/$relative"
        mkdir -p "${target%/*}"
        cp -P "$file" "$target"
        found=$((found + 1))
    done < "$file_list"
    rm "$file_list"

    if [[ $found -eq 0 ]]; then
        echo "Error: No attachments found${filter_name:+ matching '$filter_name'}" >&2
        exit 1
    fi

    echo "$tmpdir"
    echo "" >&2
    echo "Extracted $found attachment(s) to: $tmpdir" >&2
    ls -la "$tmpdir" >&2
    ATTACHMENT_TMP=""
}

# --- Main ---

case "${1:-help}" in
    help|--help|-h)
        sed -n '2,/^$/{ s/^# //; s/^#//; p; }' "$0"
        exit 0
        ;;
    search) ;;
    read|info)
        [[ $# -eq 2 ]] || fail "Usage: $0 $1 <MESSAGE_ID>"
        validate_id "$2"
        ;;
    attachment)
        [[ $# -eq 2 || $# -eq 3 ]] || fail "Usage: $0 attachment <MESSAGE_ID> [ATTACHMENT_NAME]"
        validate_id "$2"
        ;;
    mailboxes) [[ $# -eq 1 ]] || fail "Usage: $0 mailboxes" ;;
    *)
        echo "Unknown command: $1" >&2
        echo "Run '$0 help' for usage" >&2
        exit 1
        ;;
esac

command -v sqlite3 >/dev/null || fail "sqlite3 is required."
find_mail_dir

case "$1" in
    search)     shift; cmd_search "$@" ;;
    read)       cmd_read "$2" ;;
    attachment) cmd_attachment "$2" "${3:-}" ;;
    mailboxes)  cmd_mailboxes ;;
    info)       cmd_info "$2" ;;
esac
