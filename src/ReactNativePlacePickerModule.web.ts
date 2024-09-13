import type {
  PlacePickerResults,
  PlacePickerOptions,
} from "./ReactNativePlacePicker.types";

export default {
  async pickPlace(_: PlacePickerOptions): Promise<PlacePickerResults> {
    throw new Error("Method pickPlace is not available on web");
  },
};
