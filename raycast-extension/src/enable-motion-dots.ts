import { closeMainWindow, showHUD } from "@raycast/api";
import { runSickMotionAction } from "./lib/sickMotionCtl";

export default async function main() {
  await closeMainWindow({ clearRootSearch: true });

  try {
    await runSickMotionAction("enable");
    await showHUD("Motion dots enabled");
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to enable motion dots";
    await showHUD(message);
  }
}
