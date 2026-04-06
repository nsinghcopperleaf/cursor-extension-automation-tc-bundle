"use strict";

const { readFileSync } = require("fs");
const { resolve } = require("path");
const { execSync } = require("child_process");

const root = resolve(__dirname, "..");
const pkg = JSON.parse(readFileSync(resolve(root, "package.json"), "utf8"));
const version = pkg.version;
if (!version || typeof version !== "string") {
  throw new Error("package.json missing valid \"version\" field");
}

const out = `Cursor-ExtensionAutomation-Tc-bundle-${version}.vsix`;
const cmd = `npx @vscode/vsce package -o "${out}"`;

console.log(`Packaging ${pkg.name}@${version} -> ${out}`);
execSync(cmd, { cwd: root, stdio: "inherit", shell: true });
