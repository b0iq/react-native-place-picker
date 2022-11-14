import { NativeModules, Platform } from 'react-native';
import type { PlacePickerOptions, PlacePickerResults } from './interfaces';
export * from './interfaces';
const LINKING_ERROR =
  `The package 'react-native-place-picker' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// @ts-expect-error
const isTurboModuleEnabled = global.__turboModuleProxy != null;

const PlacePickerModule = isTurboModuleEnabled
  ? require('./NativePlacePicker').default
  : NativeModules.PlacePicker;

const PlacePicker = PlacePickerModule
  ? PlacePickerModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function pickPlace(
  options: PlacePickerOptions | undefined = {}
): Promise<PlacePickerResults> {
  return PlacePicker.pickPlace(options);
}
