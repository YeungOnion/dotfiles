# git filter-repo completions
# https://github.com/newren/git-filter-repo

complete -c git -n '__fish_git_needs_command' -a filter-repo -d 'Rewrite repository history'

set -l using_filter_repo '__fish_git_using_command filter-repo'

# Analysis
complete -c git -n $using_filter_repo -l analyze                 -d 'Analyze repo history without modifying it'
complete -c git -n $using_filter_repo -l report-dir        -r    -d 'Directory for analysis report'

# Path filtering
complete -c git -n $using_filter_repo -l invert-paths            -d 'Invert path selection (exclude matched paths)'
complete -c git -n $using_filter_repo -l path              -r    -d 'Exact path (file or dir) to include; repeatable'
complete -c git -n $using_filter_repo -l path-match        -r    -d 'Alias for --path'
complete -c git -n $using_filter_repo -l path-glob         -r    -d 'Glob of paths to include; repeatable'
complete -c git -n $using_filter_repo -l path-regex        -r    -d 'Regex of paths to include; repeatable'
complete -c git -n $using_filter_repo -l use-base-name           -d 'Match on file base name instead of full path'

# Path renaming
complete -c git -n $using_filter_repo -l path-rename        -r   -d 'Rename path OLD:NEW; repeatable'
complete -c git -n $using_filter_repo -l path-rename-match  -r   -d 'Alias for --path-rename'

# Path shortcuts
complete -c git -n $using_filter_repo -l paths-from-file       -r -d 'File containing path filter/rename directives'
complete -c git -n $using_filter_repo -l subdirectory-filter   -r -d 'Treat subdirectory as project root'
complete -c git -n $using_filter_repo -l to-subdirectory-filter -r -d 'Move project root into subdirectory'

# Content editing
complete -c git -n $using_filter_repo -l replace-text           -r -d 'File of expressions to replace in blob content'
complete -c git -n $using_filter_repo -l strip-blobs-bigger-than -r -d 'Strip blobs larger than SIZE (e.g. 5M, 2G)'
complete -c git -n $using_filter_repo -l strip-blobs-with-ids   -r -d 'File of blob object IDs to strip'

# Ref renaming
complete -c git -n $using_filter_repo -l tag-rename             -r -d 'Rename tags OLD:NEW prefix'

# Commit message filtering
complete -c git -n $using_filter_repo -l replace-message        -r -d 'File of expressions to replace in commit messages'
complete -c git -n $using_filter_repo -l preserve-commit-hashes    -d 'Do not update commit hash refs in messages'
complete -c git -n $using_filter_repo -l preserve-commit-encoding  -d 'Do not reencode commit messages to UTF-8'

# Names & emails
complete -c git -n $using_filter_repo -l mailmap                -r -d 'Mailmap file for rewriting author/committer/tagger'
complete -c git -n $using_filter_repo -l use-mailmap               -d 'Use .mailmap (equivalent to --mailmap .mailmap)'

# Parent rewriting
complete -c git -n $using_filter_repo -l replace-refs           -r -d 'How to handle replace refs' -a '
    delete-no-add\t"Delete existing, add none"
    delete-and-add\t"Delete existing, add new"
    update-no-add\t"Update existing, add none (default)"
    update-or-add\t"Update existing, add if none exist"
    update-and-add\t"Update existing, always add new"
    old-default\t"Pre-2.45 default behavior"
'
complete -c git -n $using_filter_repo -l prune-empty            -r -d 'Whether to prune empty commits' -a '
    auto\t"Prune only commits that become empty (default)"
    always\t"Prune all empty commits"
    never\t"Never prune empty commits"
'
complete -c git -n $using_filter_repo -l prune-degenerate       -r -d 'Whether to prune degenerate merges' -a '
    auto\t"Prune only merges that become degenerate (default)"
    always\t"Prune all degenerate merges"
    never\t"Never prune degenerate merges"
'
complete -c git -n $using_filter_repo -l no-ff                     -d 'Do not prune first parent even if ancestor of another'

# Callbacks
complete -c git -n $using_filter_repo -l filename-callback      -r -d 'Python body: process filenames (return None to drop)'
complete -c git -n $using_filter_repo -l file-info-callback     -r -d 'Python body: process file+metadata (returns filename,mode,blob_id)'
complete -c git -n $using_filter_repo -l message-callback       -r -d 'Python body: process commit/tag messages'
complete -c git -n $using_filter_repo -l name-callback          -r -d 'Python body: process author/committer/tagger names'
complete -c git -n $using_filter_repo -l email-callback         -r -d 'Python body: process email addresses'
complete -c git -n $using_filter_repo -l refname-callback       -r -d 'Python body: process ref names'
complete -c git -n $using_filter_repo -l blob-callback          -r -d 'Python body: process blob objects'
complete -c git -n $using_filter_repo -l commit-callback        -r -d 'Python body: process commit objects'
complete -c git -n $using_filter_repo -l tag-callback           -r -d 'Python body: process tag objects'
complete -c git -n $using_filter_repo -l reset-callback         -r -d 'Python body: process reset objects'

# Sensitive data removal
complete -c git -n $using_filter_repo -l sensitive-data-removal    -d 'Mode for removing sensitive data (implies --force)'
complete -c git -n $using_filter_repo -l sdr                       -d 'Alias for --sensitive-data-removal'
complete -c git -n $using_filter_repo -l no-fetch                  -d 'Skip mirror fetch from origin (--sdr only)'

# Source / target
complete -c git -n $using_filter_repo -l source                 -r -d 'Source git repository to read from'
complete -c git -n $using_filter_repo -l target                 -r -d 'Target git repository to overwrite'

# Ordering
complete -c git -n $using_filter_repo -l date-order                -d 'Process commits in commit timestamp order'

# Miscellaneous
complete -c git -n $using_filter_repo -l help              -s h   -d 'Show help and exit'
complete -c git -n $using_filter_repo -l version                  -d 'Display version and exit'
complete -c git -n $using_filter_repo -l proceed                  -d 'Skip the no-arguments-specified check'
complete -c git -n $using_filter_repo -l force             -s f   -d 'Rewrite even if repo does not look like a fresh clone'
complete -c git -n $using_filter_repo -l partial                  -d 'Partial rewrite (keep old refs, skip gc)'
complete -c git -n $using_filter_repo -l no-gc                    -d 'Do not run git gc after filtering'
complete -c git -n $using_filter_repo -l refs               -r    -d 'Limit rewrite to specified refs (implies --partial)'
complete -c git -n $using_filter_repo -l dry-run                  -d 'Show what would be done without modifying the repo'
complete -c git -n $using_filter_repo -l debug                    -d 'Print extra information about operations performed'
complete -c git -n $using_filter_repo -l stdin                    -d 'Read fast-export stream from stdin instead of running it'
complete -c git -n $using_filter_repo -l quiet                    -d 'Pass --quiet to subordinate git commands'

# ─── git-branchless completions ───────────────────────────────────────────────
# Covers aliases installed by `git branchless init` plus the standalone binary.
# Reference: git-branchless --help / <subcommand> --help

# Register git alias subcommands so they appear in `git <TAB>` completions
complete -c git -n '__fish_git_needs_command' -a sl       -d '[branchless] Visual commit graph (smartlog)'
complete -c git -n '__fish_git_needs_command' -a smartlog -d '[branchless] Visual commit graph'
complete -c git -n '__fish_git_needs_command' -a sw       -d '[branchless] Switch to branch or commit'
complete -c git -n '__fish_git_needs_command' -a next     -d '[branchless] Move to later commit in stack'
complete -c git -n '__fish_git_needs_command' -a prev     -d '[branchless] Move to earlier commit in stack'
complete -c git -n '__fish_git_needs_command' -a move     -d '[branchless] Move commit subtree to new location'
complete -c git -n '__fish_git_needs_command' -a restack  -d '[branchless] Restack commits abandoned by rewrite'
complete -c git -n '__fish_git_needs_command' -a reword   -d '[branchless] Reword commit messages'
complete -c git -n '__fish_git_needs_command' -a sync     -d '[branchless] Sync local stacks onto main branch'
complete -c git -n '__fish_git_needs_command' -a submit   -d '[branchless] Push commits to forge/remote'
complete -c git -n '__fish_git_needs_command' -a undo     -d '[branchless] Browse or return to previous repo state'
complete -c git -n '__fish_git_needs_command' -a hide     -d '[branchless] Hide commits from smartlog'
complete -c git -n '__fish_git_needs_command' -a unhide   -d '[branchless] Unhide commits from smartlog'
complete -c git -n '__fish_git_needs_command' -a amend    -d '[branchless] Amend HEAD commit and restack descendants'
complete -c git -n '__fish_git_needs_command' -a record   -d '[branchless] Interactively create a commit'
complete -c git -n '__fish_git_needs_command' -a query    -d '[branchless] Query commit graph with revset language'
complete -c git -n '__fish_git_needs_command' -a test     -d '[branchless] Run command on each commit in a set'

# Common revset expressions offered as positional-argument completions
function __branchless_revsets
    printf '%s\t%s\n' \
        '@'        'Current commit (HEAD)' \
        'stack()'  'Commits in current stack' \
        'draft()'  'All local (draft) commits' \
        'HEAD'     'HEAD commit'
    git branch --format='%(refname:short)' 2>/dev/null
end

# Shared --color argument values (used by every subcommand)
set -l _bl_color '-l color -r -d "Terminal color mode" -a "auto\tAuto-detect always\tAlways use color never\tDisable color"'

# ── sl / smartlog ──────────────────────────────────────────────────────────────
set -l _sl '__fish_git_using_command sl smartlog'
complete -c git -n $_sl -l reverse   -d 'Print latest commits first'
complete -c git -n $_sl -l exact     -d "Don't auto-add HEAD/main to commit list"
complete -c git -n $_sl -l hidden    -d 'Include hidden commits in revset results'
complete -c git -n $_sl -l event-id  -r -d 'Show smartlog at this event (negative = offset from now)'
complete -c git -n $_sl -l color     -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_sl -s h -l help -d 'Print help'
complete -c git -n $_sl -f -a '(__branchless_revsets)'

# ── next ───────────────────────────────────────────────────────────────────────
set -l _next '__fish_git_using_command next'
complete -c git -n $_next -s a -l all         -d 'Traverse as far as possible'
complete -c git -n $_next -s b -l branch      -d 'Move by branches, not individual commits'
complete -c git -n $_next -s o -l oldest      -d 'Auto-pick oldest commit when stack forks'
complete -c git -n $_next -s n -l newest      -d 'Auto-pick newest commit when stack forks'
complete -c git -n $_next -s i -l interactive -d 'Prompt to choose when stack forks'
complete -c git -n $_next -s m -l merge       -d 'Merge instead of aborting on conflict'
complete -c git -n $_next -s f -l force       -d 'Discard local changes on conflict (caution!)'
complete -c git -n $_next -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_next -s h -l help -d 'Print help'

# ── prev ───────────────────────────────────────────────────────────────────────
set -l _prev '__fish_git_using_command prev'
complete -c git -n $_prev -s a -l all         -d 'Traverse as far as possible'
complete -c git -n $_prev -s b -l branch      -d 'Move by branches, not individual commits'
complete -c git -n $_prev -s o -l oldest      -d 'Auto-pick oldest commit when stack forks'
complete -c git -n $_prev -s n -l newest      -d 'Auto-pick newest commit when stack forks'
complete -c git -n $_prev -s i -l interactive -d 'Prompt to choose when stack forks'
complete -c git -n $_prev -s m -l merge       -d 'Merge instead of aborting on conflict'
complete -c git -n $_prev -s f -l force       -d 'Discard local changes on conflict (caution!)'
complete -c git -n $_prev -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_prev -s h -l help -d 'Print help'

# ── sw (branchless switch) ────────────────────────────────────────────────────
set -l _sw '__fish_git_using_command sw'
complete -c git -n $_sw -s i -l interactive -d 'Interactively select a commit to check out'
complete -c git -n $_sw -s c -l create   -r -d 'Create branch pointing to target commit'
complete -c git -n $_sw -s f -l force       -d 'Discard working copy changes if needed'
complete -c git -n $_sw -s m -l merge       -d 'Start merge resolution instead of aborting on conflict'
complete -c git -n $_sw -s d -l detach      -d 'Detach HEAD after switching to branch'
complete -c git -n $_sw -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_sw -s h -l help -d 'Print help'
complete -c git -n $_sw -f -a '(__fish_git_branches)'
complete -c git -n $_sw -f -a '(__fish_git_tags)'
complete -c git -n $_sw -f -a '(__branchless_revsets)'

# ── move ───────────────────────────────────────────────────────────────────────
set -l _move '__fish_git_using_command move'
complete -c git -n $_move -s s -l source  -r -d 'Source commit (+ all descendants) to move'
complete -c git -n $_move -s b -l base    -r -d 'Commit inside subtree to move (entire subtree from main)'
complete -c git -n $_move -s x -l exact   -r -d 'Specific commits to move (unmoved children lifted to ancestor)'
complete -c git -n $_move -s d -l dest    -r -d 'Destination commit (default: HEAD)'
complete -c git -n $_move -s F -l fixup      -d 'Squash moved commits into destination'
complete -c git -n $_move -s I -l insert     -d 'Insert subtree between dest and its children'
complete -c git -n $_move -s f -l force-rewrite -d 'Allow moving public commits'
complete -c git -n $_move -s m -l merge      -d 'Attempt merge on conflict instead of aborting'
complete -c git -n $_move -l in-memory       -d 'In-memory rebase only; abort if it fails'
complete -c git -n $_move -l on-disk         -d 'Skip in-memory attempt; use on-disk rebase directly'
complete -c git -n $_move -l no-deduplicate-commits -d 'Skip deduplication of already-applied commits'
complete -c git -n $_move -l hidden          -d 'Include hidden commits in revset evaluation'
complete -c git -n $_move -l debug-dump-rebase-constraints -d 'Print rebase constraints before executing'
complete -c git -n $_move -l debug-dump-rebase-plan        -d 'Print rebase plan before executing'
complete -c git -n $_move -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_move -s h -l help -d 'Print help'

# ── restack ────────────────────────────────────────────────────────────────────
set -l _restack '__fish_git_using_command restack'
complete -c git -n $_restack -s f -l force-rewrite -d 'Allow restacking public commits'
complete -c git -n $_restack -s m -l merge          -d 'Attempt merge on conflict instead of aborting'
complete -c git -n $_restack -l in-memory           -d 'In-memory rebase only; abort if it fails'
complete -c git -n $_restack -l on-disk             -d 'Skip in-memory attempt; use on-disk rebase directly'
complete -c git -n $_restack -l no-deduplicate-commits -d 'Skip deduplication of already-applied commits'
complete -c git -n $_restack -l hidden              -d 'Include hidden commits in revset evaluation'
complete -c git -n $_restack -l debug-dump-rebase-constraints -d 'Print rebase constraints before executing'
complete -c git -n $_restack -l debug-dump-rebase-plan        -d 'Print rebase plan before executing'
complete -c git -n $_restack -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_restack -s h -l help -d 'Print help'
complete -c git -n $_restack -f -a '(__branchless_revsets)'

# ── reword ─────────────────────────────────────────────────────────────────────
set -l _reword '__fish_git_using_command reword'
complete -c git -n $_reword -s m -l message  -r -d 'Commit message (repeat for multiple paragraphs)'
complete -c git -n $_reword -s d -l discard     -d 'Discard original message; open editor fresh'
complete -c git -n $_reword -l fixup        -r  -d 'Create fixup! commit targeting this commit'
complete -c git -n $_reword -s f -l force-rewrite -d 'Allow rewording public commits'
complete -c git -n $_reword -l hidden           -d 'Include hidden commits in revset evaluation'
complete -c git -n $_reword -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_reword -s h -l help -d 'Print help'
complete -c git -n $_reword -f -a '(__branchless_revsets)'

# ── sync ───────────────────────────────────────────────────────────────────────
set -l _sync '__fish_git_using_command sync'
complete -c git -n $_sync -s p -l pull          -d 'Fetch from remote before syncing (aliases: --update, -u)'
complete -c git -n $_sync -s f -l force-rewrite -d 'Allow syncing public commits'
complete -c git -n $_sync -s m -l merge         -d 'Attempt merge on conflict instead of aborting'
complete -c git -n $_sync -l in-memory          -d 'In-memory rebase only; abort if it fails'
complete -c git -n $_sync -l on-disk            -d 'Skip in-memory attempt; use on-disk rebase directly'
complete -c git -n $_sync -l no-deduplicate-commits -d 'Skip deduplication of already-applied commits'
complete -c git -n $_sync -l hidden             -d 'Include hidden commits in revset evaluation'
complete -c git -n $_sync -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_sync -s h -l help -d 'Print help'
complete -c git -n $_sync -f -a '(__branchless_revsets)'

# ── submit ─────────────────────────────────────────────────────────────────────
set -l _submit '__fish_git_using_command submit'
complete -c git -n $_submit -s F -l forge -r -d 'Hosting provider (auto-detected if omitted)' \
    -a "branch\t'Force-push branches to remote' github\t'Create/update PRs via gh CLI' phabricator\t'Submit via arc CLI'"
complete -c git -n $_submit -s c -l create  -d 'Create remote object when none exists'
complete -c git -n $_submit -s d -l draft   -d 'Create code reviews in draft mode'
complete -c git -n $_submit -s m -l message -r -d 'Message to include with create/update operation'
complete -c git -n $_submit -s n -l dry-run -d 'Report what would be pushed without doing it'
complete -c git -n $_submit -s j -l jobs    -r -d 'Parallel jobs (0 = use all CPUs)'
complete -c git -n $_submit -s s -l strategy -r -d 'Tool execution strategy' \
    -a "working-copy\t'Run in current working copy (requires clean tree)' worktree\t'Run in a separate managed worktree'"
complete -c git -n $_submit -l hidden       -d 'Include hidden commits in revset evaluation'
complete -c git -n $_submit -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_submit -s h -l help -d 'Print help'
complete -c git -n $_submit -f -a '(__branchless_revsets)'

# ── undo ───────────────────────────────────────────────────────────────────────
set -l _undo '__fish_git_using_command undo'
complete -c git -n $_undo -s i -l interactive -d 'Browse past states before selecting one to restore'
complete -c git -n $_undo -s y -l yes         -d 'Skip confirmation; apply immediately'
complete -c git -n $_undo -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_undo -s h -l help -d 'Print help'

# ── hide ───────────────────────────────────────────────────────────────────────
set -l _hide '__fish_git_using_command hide'
complete -c git -n $_hide -s r -l recursive       -d 'Also hide all visible children commits'
complete -c git -n $_hide -l no-delete-branches   -d "Don't delete branches pointing to hidden commits"
complete -c git -n $_hide -l hidden               -d 'Include hidden commits in revset evaluation'
complete -c git -n $_hide -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_hide -s h -l help -d 'Print help'
complete -c git -n $_hide -f -a '(__branchless_revsets)'

# ── unhide ─────────────────────────────────────────────────────────────────────
set -l _unhide '__fish_git_using_command unhide'
complete -c git -n $_unhide -s r -l recursive -d 'Also recursively unhide all children commits'
complete -c git -n $_unhide -l hidden         -d 'Include hidden commits in revset evaluation'
complete -c git -n $_unhide -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_unhide -s h -l help -d 'Print help'
complete -c git -n $_unhide -f -a '(__branchless_revsets)'

# ── amend ──────────────────────────────────────────────────────────────────────
set -l _amend '__fish_git_using_command amend'
complete -c git -n $_amend -l reparent          -d 'Keep descendants contents identical; only reparent them'
complete -c git -n $_amend -s f -l force-rewrite -d 'Allow amending public commits'
complete -c git -n $_amend -s m -l merge         -d 'Attempt merge on conflict instead of aborting'
complete -c git -n $_amend -l in-memory          -d 'In-memory rebase only; abort if it fails'
complete -c git -n $_amend -l on-disk            -d 'Skip in-memory attempt; use on-disk rebase directly'
complete -c git -n $_amend -l no-deduplicate-commits -d 'Skip deduplication of already-applied commits'
complete -c git -n $_amend -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_amend -s h -l help -d 'Print help'

# ── record ─────────────────────────────────────────────────────────────────────
set -l _record '__fish_git_using_command record'
complete -c git -n $_record -s m -l message  -r -d 'Commit message (prompted if omitted)'
complete -c git -n $_record -s i -l interactive -d 'Interactively select which changes to include'
complete -c git -n $_record -s c -l create   -r -d 'Create and switch to a new branch before committing'
complete -c git -n $_record -s d -l detach      -d 'Detach current branch before committing'
complete -c git -n $_record -s I -l insert      -d 'Insert new commit between HEAD and its children'
complete -c git -n $_record -s s -l stash       -d 'Switch back to previous commit after committing'
complete -c git -n $_record -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_record -s h -l help -d 'Print help'

# ── query ──────────────────────────────────────────────────────────────────────
set -l _query '__fish_git_using_command query'
complete -c git -n $_query -s b -l branches -d 'Print branch names instead of commit OIDs'
complete -c git -n $_query -s r -l raw      -d 'Print raw OIDs, one per line (stable for scripts)'
complete -c git -n $_query -l hidden        -d 'Include hidden commits in revset evaluation'
complete -c git -n $_query -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_query -s h -l help -d 'Print help'
complete -c git -n $_query -f -a '(__branchless_revsets)'

# ── test ───────────────────────────────────────────────────────────────────────
# `git test` has its own subcommands: run, show, clean, fix
set -l _test     '__fish_git_using_command test'
set -l _test_run '__fish_git_using_command test; and __fish_seen_subcommand_from run'
set -l _test_fix '__fish_git_using_command test; and __fish_seen_subcommand_from fix'
set -l _test_show '__fish_git_using_command test; and __fish_seen_subcommand_from show'

# Offer subcommands when none is selected yet
complete -c git -n "$_test; and not __fish_seen_subcommand_from run show clean fix" -f \
    -a "run\t'Run command on each commit' show\t'Show cached test results' clean\t'Clear cached results' fix\t'Run command and amend passing commits'"
complete -c git -n $_test -l color -r -d 'Terminal color' -a "auto\tAuto-detect always\tAlways never\tDisable"
complete -c git -n $_test -s h -l help -d 'Print help'

# Shared test options (run/fix/show)
set -l _test_exec_opts "-s x -l exec -r -d 'Ad-hoc command to run on each commit'"
complete -c git -n $_test_run  -s x -l exec    -r -d 'Ad-hoc command to run on each commit'
complete -c git -n $_test_run  -s c -l command -r -d 'Named alias from branchless.test.alias.<name>'
complete -c git -n $_test_run  -s v -l verbose    -d 'Show test output (repeat for more detail)'
complete -c git -n $_test_run  -s s -l strategy -r -d 'Execution strategy' \
    -a "working-copy\t'Run in working copy (needs clean tree)' worktree\t'Run in separate managed worktree'"
complete -c git -n $_test_run  -s S -l search  -r -d 'Find first failing commit' \
    -a "linear\t'Oldest to newest, exit on first fail' reverse\t'Newest to oldest, exit on first pass' binary\t'Binary search for failure boundary'"
complete -c git -n $_test_run  -s b -l bisect    -d 'Shorthand for --search binary'
complete -c git -n $_test_run  -s j -l jobs    -r -d 'Parallel jobs (0 = all CPUs)'
complete -c git -n $_test_run  -s i -l interactive -d 'Run in foreground for interactive commands'
complete -c git -n $_test_run  -l no-cache        -d 'Bypass read/write of result cache'
complete -c git -n $_test_run  -l hidden          -d 'Include hidden commits in revset evaluation'
complete -c git -n $_test_run  -s h -l help -d 'Print help'
complete -c git -n $_test_run  -f -a '(__branchless_revsets)'

complete -c git -n $_test_fix  -s x -l exec    -r -d 'Ad-hoc command to run on each commit'
complete -c git -n $_test_fix  -s c -l command -r -d 'Named alias from branchless.test.alias.<name>'
complete -c git -n $_test_fix  -s n -l dry-run    -d 'Print summary without rewriting any commits'
complete -c git -n $_test_fix  -s v -l verbose    -d 'Show test output (repeat for more detail)'
complete -c git -n $_test_fix  -s j -l jobs    -r -d 'Parallel jobs (0 = all CPUs)'
complete -c git -n $_test_fix  -s s -l strategy -r -d 'Execution strategy' \
    -a "working-copy\t'Run in working copy (needs clean tree)' worktree\t'Run in separate managed worktree'"
complete -c git -n $_test_fix  -s f -l force-rewrite -d 'Allow rewriting public commits'
complete -c git -n $_test_fix  -s m -l merge         -d 'Attempt merge on conflict instead of aborting'
complete -c git -n $_test_fix  -l in-memory          -d 'In-memory rebase only; abort if it fails'
complete -c git -n $_test_fix  -l on-disk            -d 'Skip in-memory attempt; use on-disk rebase directly'
complete -c git -n $_test_fix  -l no-cache           -d 'Bypass read/write of result cache'
complete -c git -n $_test_fix  -l no-deduplicate-commits -d 'Skip deduplication of already-applied commits'
complete -c git -n $_test_fix  -l hidden             -d 'Include hidden commits in revset evaluation'
complete -c git -n $_test_fix  -s h -l help -d 'Print help'
complete -c git -n $_test_fix  -f -a '(__branchless_revsets)'

complete -c git -n $_test_show -s x -l exec    -r -d 'Filter results to this command'
complete -c git -n $_test_show -s c -l command -r -d 'Named alias from branchless.test.alias.<name>'
complete -c git -n $_test_show -s v -l verbose    -d 'Show full test output'
complete -c git -n $_test_show -l hidden          -d 'Include hidden commits in revset evaluation'
complete -c git -n $_test_show -s h -l help -d 'Print help'
complete -c git -n $_test_show -f -a '(__branchless_revsets)'
