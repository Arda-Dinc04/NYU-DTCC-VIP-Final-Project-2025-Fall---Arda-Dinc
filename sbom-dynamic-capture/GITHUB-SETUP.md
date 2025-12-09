# GitHub Repository Setup Guide

## Repository Name

**Format:** `NYU-DTCC-VIP Final Project 2025 Fall - Your Name`

Example: `NYU-DTCC-VIP Final Project 2025 Fall - John Doe`

## Initial Setup

### 1. Create Repository on GitHub

1. Go to [GitHub](https://github.com)
2. Click "New repository"
3. Repository name: `NYU-DTCC-VIP Final Project 2025 Fall - Your Name`
4. Description: `SBOM Generator with Dynamic Dependency Capture - NYU DTCC VIP Final Project`
5. Set to **Public**
6. **DO NOT** initialize with README, .gitignore, or license (we already have these)
7. Click "Create repository"

### 2. Initialize Local Repository

```bash
cd sbom-dynamic-capture

# Initialize git
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: SBOM generator with dynamic dependency capture"

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/NYU-DTCC-VIP-Final-Project-2025-Fall-Your-Name.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### 3. Repository Structure

Your repository should have:

```
NYU-DTCC-VIP-Final-Project-2025-Fall-Your-Name/
├── README.md              # Main documentation
├── EXAMPLES.md            # Usage examples
├── GITHUB-SETUP.md        # This file
├── sbom-with-dynamic.sh   # Main tool script
├── merge-sbom.py          # SBOM merger
├── test-demo.sh           # Test script
├── .gitignore             # Git ignore rules
└── output/                # (gitignored - generated files)
```

## Submission

### Deadline: December 12, 2025

### Submission Steps:

1. **Ensure repository is public**
2. **Verify all files are committed and pushed**
3. **Add repository link to your VIP notebook**

### Repository Link Format:

```
https://github.com/YOUR_USERNAME/NYU-DTCC-VIP-Final-Project-2025-Fall-Your-Name
```

## Verification Checklist

Before submitting, verify:

- [ ] Repository is public
- [ ] All code files are present
- [ ] README.md is complete and clear
- [ ] Scripts are executable (`chmod +x`)
- [ ] `.gitignore` is configured
- [ ] Repository name follows the required format
- [ ] Code is tested and working
- [ ] Examples are documented

## Additional Files to Consider

You may want to add:

- `LICENSE` - If you want to specify a license
- `CONTRIBUTING.md` - If accepting contributions
- Screenshots in `docs/` or `images/` folder
- Video demo link in README

## Troubleshooting

### Push Rejected

If you get "push rejected", you may need to pull first:

```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### Permission Denied

Make sure you're authenticated with GitHub:

```bash
# Check remote URL
git remote -v

# If using HTTPS, you may need a personal access token
# Or switch to SSH:
git remote set-url origin git@github.com:YOUR_USERNAME/REPO-NAME.git
```

## Final Notes

- Keep the repository active and maintained
- Respond to any issues or questions
- Consider adding tags/releases for major versions
- Update README with any improvements

Good luck with your submission! 🚀

