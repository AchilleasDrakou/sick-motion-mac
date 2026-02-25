import { getPreferenceValues } from "@raycast/api";
import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

type SickMotionAction = "toggle" | "enable" | "disable";

type Preferences = {
  sickMotionCtlPath?: string;
};

function candidatePaths(preferencePath?: string): string[] {
  const base = [
    join(process.cwd(), "..", "dist", "sickmotionctl"),
    "/usr/local/bin/sickmotionctl",
    "/opt/homebrew/bin/sickmotionctl",
    join(homedir(), ".local", "bin", "sickmotionctl"),
    join(process.cwd(), ".build", "release", "sickmotionctl")
  ];

  if (!preferencePath?.trim()) {
    return base;
  }

  return [preferencePath.trim(), ...base];
}

function resolveBinaryPath(): string {
  const { sickMotionCtlPath } = getPreferenceValues<Preferences>();
  const binary = candidatePaths(sickMotionCtlPath).find((path) => existsSync(path));

  if (!binary) {
    throw new Error(
      "Could not find sickmotionctl. Build and install it first, for example: `swift build -c release && cp .build/release/sickmotionctl /usr/local/bin/`."
    );
  }

  return binary;
}

export async function runSickMotionAction(action: SickMotionAction): Promise<void> {
  const binary = resolveBinaryPath();
  await execFileAsync(binary, [action], { timeout: 3000 });
}
