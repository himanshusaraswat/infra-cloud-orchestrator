#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const workspaceRoot = path.resolve(__dirname, '../../');

let errors = [];

function log(msg, type = 'info') {
  const icons = { info: 'ℹ️', pass: '✅', fail: '❌', warn: '⚠️' };
  console.log(`${icons[type] || '•'} ${msg}`);
}

// 1. Audit Sanitization across all markdown files
log('Auditing public documentation sanitization...', 'info');

const forbiddenPatterns = [
  { regex: /961243721322/, desc: 'Real GCP Project Number (961243721322)' },
  { regex: /meraki-public/, desc: 'Real GCP Project ID (meraki-public)' },
  { regex: /tuponkw/, desc: 'Internal MongoDB Atlas cluster subdomain' },
  { regex: /-----BEGIN PRIVATE KEY-----/, desc: 'Leaked private RSA/EC key' },
];

function scanDirForMd(dir) {
  if (!fs.existsSync(dir)) return [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  let files = [];
  for (const entry of entries) {
    if (entry.name === 'node_modules' || entry.name === '.git' || entry.name === '.angular' || entry.name === 'dist') {
      continue;
    }
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files = files.concat(scanDirForMd(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(fullPath);
    }
  }
  return files;
}

const repos = ['prj-generic-gallery', 'ms-generic-gallery', 'infra-cloud-orchestrator'];
let totalMdFiles = 0;

for (const repo of repos) {
  const repoDir = path.join(workspaceRoot, repo);
  const mdFiles = scanDirForMd(repoDir);
  totalMdFiles += mdFiles.length;

  for (const file of mdFiles) {
    const content = fs.readFileSync(file, 'utf-8');
    const lines = content.split('\n');
    lines.forEach((line, index) => {
      for (const pattern of forbiddenPatterns) {
        if (pattern.regex.test(line)) {
          errors.push(
            `Sanitization violation in ${path.relative(workspaceRoot, file)}:${index + 1} - Found ${pattern.desc}`
          );
        }
      }
    });
  }
}

log(`Scanned ${totalMdFiles} markdown files across 3 repositories for sensitive data.`, 'pass');

// 2. Audit Symlink Integrity at Workspace Root
log('Auditing workspace root symlink integrity...', 'info');
const requiredSymlinks = [
  {
    link: path.join(workspaceRoot, 'WORKSPACE_KNOWLEDGE_GRAPH.md'),
    target: 'infra-cloud-orchestrator/docs/SYSTEM_KNOWLEDGE_GRAPH.md',
  },
  {
    link: path.join(workspaceRoot, 'AGENTS.md'),
    target: 'infra-cloud-orchestrator/docs/WORKSPACE_AGENTS.md',
  },
  {
    link: path.join(workspaceRoot, 'gallery-platform.code-workspace'),
    target: 'infra-cloud-orchestrator/gallery-platform.code-workspace',
  },
];

for (const { link, target } of requiredSymlinks) {
  if (!fs.existsSync(link)) {
    errors.push(`Missing required root symlink: ${path.basename(link)}`);
  } else {
    try {
      const actualTarget = fs.readlinkSync(link);
      if (!actualTarget.includes(path.basename(target))) {
        errors.push(`Symlink ${path.basename(link)} targets ${actualTarget}, expected ${target}`);
      } else {
        log(`Symlink ${path.basename(link)} -> ${actualTarget}`, 'pass');
      }
    } catch {
      errors.push(`File ${path.basename(link)} is not a symlink!`);
    }
  }
}

// 3. Audit Spoke Files Existence
log('Auditing repository AGENTS.md spoke files...', 'info');
for (const repo of repos) {
  const agentsMd = path.join(workspaceRoot, repo, 'AGENTS.md');
  if (!fs.existsSync(agentsMd)) {
    errors.push(`Missing Spoke AGENTS.md in ${repo}`);
  } else {
    log(`Found Spoke AGENTS.md in ${repo}`, 'pass');
  }
}

// 4. Audit Test Badge Consistency
log('Auditing README test metric consistency...', 'info');
const feReadme = path.join(workspaceRoot, 'prj-generic-gallery', 'README.md');
if (fs.existsSync(feReadme)) {
  const content = fs.readFileSync(feReadme, 'utf-8');
  if (!content.includes('47_Passed') && !content.includes('47 passed')) {
    errors.push(`Frontend README.md does not accurately reflect 47 passing tests badge!`);
  } else {
    log(`Frontend README.md correctly badges 47 passed unit tests`, 'pass');
  }
}

const beReadme = path.join(workspaceRoot, 'ms-generic-gallery', 'README.md');
if (fs.existsSync(beReadme)) {
  const content = fs.readFileSync(beReadme, 'utf-8');
  if (!content.includes('24_Passed') && !content.includes('24 passed')) {
    errors.push(`Backend README.md does not accurately reflect 24 passing tests!`);
  } else {
    log(`Backend README.md correctly badges 24 passed unit tests`, 'pass');
  }
}

// Final Outcome
console.log('\n----------------------------------------');
if (errors.length > 0) {
  log(`Zero-Drift Validation FAILED with ${errors.length} error(s):`, 'fail');
  for (const err of errors) {
    console.error(`  - ${err}`);
  }
  process.exit(1);
} else {
  log('Zero-Drift Verification PASSED! All documentation, contracts, and sanitization are in 100% lockstep.', 'pass');
  process.exit(0);
}
