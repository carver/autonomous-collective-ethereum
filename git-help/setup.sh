# Install whitespace git hook for repository:
# Run from repository root dir

GIT_HELP_DIR=$(dirname "$(realpath $0)" )
if [ -f "$GIT_HELP_DIR/whitespace-precommit.sh" ]
then
    ln -fs "$GIT_HELP_DIR/whitespace-precommit.sh" .git/hooks/pre-commit
else
    echo '\nError: Fix whitespace script not found repository.'
fi
