#!/bin/bash

# Helper script to set up GitHub remote and push

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  GitHub Repository Setup                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Get repository name
read -p "Enter your GitHub username: " GITHUB_USER
read -p "Enter your name (for repo name): " YOUR_NAME

REPO_NAME="NYU-DTCC-VIP-Final-Project-2025-Fall-${YOUR_NAME// /-}"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo ""
echo "Repository name will be: ${REPO_NAME}"
echo "Repository URL will be: ${REPO_URL}"
echo ""
read -p "Have you created this repository on GitHub? (y/n): " CREATED

if [ "$CREATED" != "y" ] && [ "$CREATED" != "Y" ]; then
    echo ""
    echo "Please create the repository on GitHub first:"
    echo "1. Go to https://github.com/new"
    echo "2. Repository name: ${REPO_NAME}"
    echo "3. Description: SBOM Generator with Dynamic Dependency Capture - NYU DTCC VIP Final Project"
    echo "4. Set to PUBLIC"
    echo "5. DO NOT initialize with README, .gitignore, or license"
    echo "6. Click 'Create repository'"
    echo ""
    read -p "Press Enter when you've created the repository..."
fi

echo ""
echo "Setting up remote and pushing..."
echo ""

# Set branch to main
git branch -M main

# Add remote
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"

# Push
echo "Pushing to GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "Repository URL: ${REPO_URL}"
    echo ""
    echo "Next steps:"
    echo "1. Verify the repository is public"
    echo "2. Add the link to your VIP notebook"
    echo "3. Deadline: December 12, 2025"
else
    echo ""
    echo "❌ Push failed. Common issues:"
    echo "1. Repository doesn't exist yet - create it on GitHub first"
    echo "2. Authentication required - you may need to set up a personal access token"
    echo "3. Check your internet connection"
    echo ""
    echo "To retry manually:"
    echo "  git remote add origin ${REPO_URL}"
    echo "  git push -u origin main"
fi

