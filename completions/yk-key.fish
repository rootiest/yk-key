# Copyright (C) 2026 Rootiest
# SPDX-License-Identifier: AGPL-3.0-or-later

# fish completions for yk-key. Install as
# ~/.config/fish/completions/yk-key.fish (or any directory in
# $fish_complete_path).

# Keys in the database yk-key would read, honouring a --db/-d already typed.
function __yk_key_entries
    type -q yk-key; or return
    type -q jq; or return
    set -l tokens (commandline -xpc)
    set -e tokens[1]
    argparse -i 'd/db=' -- $tokens 2>/dev/null; or return
    set -l db_args
    set -q _flag_db; and set db_args --db $_flag_db
    command yk-key list --json --long $db_args 2>/dev/null \
        | command jq -r '.[] | "\(.name)\t\(.fingerprint) | \(.serial)"' 2>/dev/null
end

set -l subcmds list ls info show current inserted add edit rm delete remove git help
set -l query_cmds info show edit rm delete remove git
set -l field_cmds list ls info show current inserted git

complete -c yk-key -f

# Subcommands (only as the first argument).
set -l none "not __fish_seen_subcommand_from $subcmds"
complete -c yk-key -n $none -a list -d 'List every key (default)'
complete -c yk-key -n $none -a ls -d 'List every key'
complete -c yk-key -n $none -a info -d 'Look up one key'
complete -c yk-key -n $none -a show -d 'Look up one key'
complete -c yk-key -n $none -a current -d 'Show the inserted YubiKey'
complete -c yk-key -n $none -a inserted -d 'Show the inserted YubiKey'
complete -c yk-key -n $none -a add -d 'Add a key interactively'
complete -c yk-key -n $none -a edit -d 'Edit a key interactively'
complete -c yk-key -n $none -a rm -d 'Remove a key'
complete -c yk-key -n $none -a delete -d 'Remove a key'
complete -c yk-key -n $none -a remove -d 'Remove a key'
complete -c yk-key -n $none -a git -d 'Show or set Git user.signingkey'
complete -c yk-key -n $none -a help -d 'Show help'

# Key names: a bare QUERY (an implicit info) or after a query subcommand.
complete -c yk-key -n "$none; or __fish_seen_subcommand_from $query_cmds" -a '(__yk_key_entries)'

# Output fields and fingerprint length.
set -l fields "$none; or __fish_seen_subcommand_from $field_cmds"
complete -c yk-key -n $fields -s n -l name -d 'Print only the key name'
complete -c yk-key -n $fields -s f -l fingerprint -d 'Print only the fingerprint'
complete -c yk-key -n $fields -s s -l serial -d 'Print only the serial number'
complete -c yk-key -n $fields -s k -l ssh-key -d 'Print only the SSH key path'
complete -c yk-key -n $fields -s l -l length -x -a 'short\t"8 characters" long\t"16 characters" full\t"40 characters"' -d 'Fingerprint length'
complete -c yk-key -n $fields -l short -d 'Short 8-character key ID'
complete -c yk-key -n $fields -l long -d 'Long 16-character key ID'
complete -c yk-key -n $fields -l full -d 'Full 40-character fingerprint'

# Query matching.
set -l queries "$none; or __fish_seen_subcommand_from $query_cmds"
complete -c yk-key -n $queries -s N -l by-name -d 'Match names only'
complete -c yk-key -n $queries -s F -l by-fingerprint -d 'Match fingerprints only'
complete -c yk-key -n $queries -s S -l by-serial -d 'Match serials only'

# Subcommand-specific flags.
complete -c yk-key -n '__fish_seen_subcommand_from git' -s g -l global -d 'Use the global Git config'
complete -c yk-key -n '__fish_seen_subcommand_from rm delete remove' -s y -l yes -d 'Do not ask for confirmation'

# General flags.
complete -c yk-key -s d -l db -r -F -d 'Use PATH as the database'
complete -c yk-key -s j -l json -d 'Print machine-readable JSON'
complete -c yk-key -s q -l silent -d 'Print only the data'
complete -c yk-key -l quiet -d 'Print only the data'
complete -c yk-key -s C -l no-color -d 'Disable coloured output'
complete -c yk-key -s V -l version -d 'Print the version'
complete -c yk-key -s h -l help -d 'Show help'
