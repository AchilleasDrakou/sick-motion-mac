import { closeMainWindow, showHUD } from "@raycast/api";
import { runSickMotionAction } from "./lib/sickMotionCtl";

export default async function main() {
  await closeMainWindow({ clearRootSearch: true });

  try {
    await runSickMotionAction("disable");
    await showHUD("Motion dots disabled");
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to disable motion dots";
    await showHUD(message);
  }
}
