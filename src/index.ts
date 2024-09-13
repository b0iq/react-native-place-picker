import type {
  PlacePickerOptions,
  PlacePickerResults,
} from "./ReactNativePlacePicker.types";
import ReactNativePlacePickerModule from "./ReactNativePlacePickerModule";

export async function pickPlace(
  options?: PlacePickerOptions
): Promise<PlacePickerResults> {
  return await ReactNativePlacePickerModule.pickPlace(options);
}

export * from "./ReactNativePlacePicker.types";
