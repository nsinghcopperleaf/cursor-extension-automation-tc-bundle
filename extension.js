"use strict";

const vscode = require("vscode");
const path = require("path");
const fs = require("fs");

/**
 * Do not overwrite HONI Workflow config if the user already filled it in.
 * @param {string} dest
 */
function shouldSkipDestFile(dest) {
  const marker = path.join("HONI", "Workflow", "config.json");
  if (!dest.endsWith(marker) && !dest.replace(/\//g, "\\").endsWith(marker)) {
    return false;
  }
  return fs.existsSync(dest);
}

/**
 * @param {string} src
 * @param {string} dest
 */
function copyRecursiveMerge(src, dest) {
  if (!fs.existsSync(src)) {
    return;
  }
  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    fs.mkdirSync(dest, { recursive: true });
    for (const name of fs.readdirSync(src)) {
      if (name === ".git") {
        continue;
      }
      copyRecursiveMerge(path.join(src, name), path.join(dest, name));
    }
  } else {
    if (shouldSkipDestFile(dest)) {
      return;
    }
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  }
}

function getCursorDir() {
  const home = process.env.USERPROFILE || process.env.HOME || "";
  return path.join(home, ".cursor");
}

function syncBundle() {
  const extPath = path.dirname(__filename);
  const bundleRoot = path.join(extPath, "bundled");
  const cursorDir = getCursorDir();

  const mappings = [
    { label: "rules", from: path.join(bundleRoot, "rules"), to: path.join(cursorDir, "rules") },
    { label: "skills", from: path.join(bundleRoot, "skills"), to: path.join(cursorDir, "skills") },
    {
      label: "AI_AUTOMATION",
      from: path.join(bundleRoot, "AI_AUTOMATION"),
      to: path.join(cursorDir, "AI_AUTOMATION"),
    },
  ];

  for (const { label, from, to } of mappings) {
    if (!fs.existsSync(from)) {
      vscode.window.showWarningMessage(`HONI bundle: missing bundled folder "${label}".`);
      continue;
    }
    copyRecursiveMerge(from, to);
  }

  void vscode.window.showInformationMessage(
    "HONI bundle synced to ~/.cursor (rules, skills, AI_AUTOMATION TC001–003)."
  );
}

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
  syncBundle();
  context.subscriptions.push(
    vscode.commands.registerCommand("cursorHoniBundle.syncNow", syncBundle)
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
