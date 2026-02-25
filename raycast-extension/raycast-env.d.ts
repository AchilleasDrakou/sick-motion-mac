/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** sickmotionctl Path - Optional full path to the sickmotionctl binary. */
  "sickMotionCtlPath"?: string
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `toggle-motion-dots` command */
  export type ToggleMotionDots = ExtensionPreferences & {}
  /** Preferences accessible in the `enable-motion-dots` command */
  export type EnableMotionDots = ExtensionPreferences & {}
  /** Preferences accessible in the `disable-motion-dots` command */
  export type DisableMotionDots = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `toggle-motion-dots` command */
  export type ToggleMotionDots = {}
  /** Arguments passed to the `enable-motion-dots` command */
  export type EnableMotionDots = {}
  /** Arguments passed to the `disable-motion-dots` command */
  export type DisableMotionDots = {}
}

