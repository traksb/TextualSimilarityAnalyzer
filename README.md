# SQL Scripts Documentation

This repository contains SQL scripts that serve specific purposes related to text-base answer analysis. Below is a breakdown of each script, its purpose, and usage instructions.

## Table of Contents

1. [Submission Similarity Checker](#submission-similarity-checker)
2. [Submission Comparison](#submission-comparison)

---

## Submission Similarity Checker

**File Name:** `SubmissionSimilarityChecker.sql`

**Purpose:** This script identifies similar submissions based on text responses. It compares 'completed' submissions (newly received and needing checks) with 'passed' submissions (already approved). The script uses string matching for older submissions and similarity functions for recent ones.

**Usage:**
1. Replace `{{Project ID}}` with the specific project ID you're targeting.
2. Run the script in your SQL environment.

[View Code](./SubmissionSimilarityChecker.sql)

---

## Submission Comparison

**File Name:** `SubmissionComparison.sql`

**Purpose:** This script compares responses from different submission statuses. It mainly distinguishes between 'completed' (newly received) and 'passed' (already approved) submissions. The comparison assesses the similarity of answers based on their text, user, and item IDs.

**Usage:**
1. Replace `{{Project ID}}` with the specific project ID you're targeting.
2. Run the script in your SQL environment.

[View Code](./SubmissionComparison.sql)

---

**Note:** Ensure that you have the necessary permissions and that the database is properly backed up before running any script. It's also recommended to run these scripts in a test environment first.

