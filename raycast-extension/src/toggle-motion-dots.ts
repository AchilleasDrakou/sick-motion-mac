import { closeMainWindow, showHUD } from "@raycast/api";
import { runSickMotionAction } from "./lib/sickMotionCtl";

export default async function main() {
  await closeMainWindow({ clearRootSearch: true });

  try {
    await runSickMotionAction("toggle");
    await showHUD("Motion dots toggled");
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to toggle motion dots";
    await showHUD(message);
  }
}
