#!/bin/bash

# Set repository directory
REPO_DIR="$1"

# Check if repository directory is provided
if [ -z "$REPO_DIR" ]; then
  echo "Usage: $0 <repository_directory>"
  exit 1
fi

# Check if repository directory exists
if [ ! -d "$REPO_DIR" ]; then
  echo "Error: Repository directory '$REPO_DIR' does not exist."
  exit 1
fi

# Change to the repository directory
cd "$REPO_DIR"

# Check if git repository
if [ ! -d ".git" ]; then
  echo "Error: '$REPO_DIR' is not a git repository."
  exit 1
fi


# Get the current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Add all changes
git add .

# Check if there are any changes to commit
if ! git diff-index --quiet HEAD --; then

  # Get the current date and time for the commit message
  COMMIT_MESSAGE=$(date +"%Y-%m-%d %H:%M:%S - Automated commit")


  # Commit the changes
  git commit -m "$COMMIT_MESSAGE"

  # Push the changes
  git push origin "$CURRENT_BRANCH"

  echo "Successfully committed and pushed changes to origin/$CURRENT_BRANCH"

else
  echo "No changes to commit."
fi

exit 0
