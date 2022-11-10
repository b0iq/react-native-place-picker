import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-place-picker' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const PlacePicker = NativeModules.PlacePicker
  ? NativeModules.PlacePicker
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export interface PickerCoordinates {
  latitude: number;
  longitude: number;
}
export interface PickerOptions {
  initialCoordinates?: PickerCoordinates;
  title?: String;
  searchPlaceholder?: String;
  accentColor?: String;
  locale?: String;
}
export interface PickerResults extends PickerCoordinates {
  canceled: boolean;
  address?: any;
}

export function pickPlace(
  options: PickerOptions | undefined = undefined
): Promise<PickerResults> {
  if (options !== undefined) {
    return PlacePicker.pickPlaceWithOptions(options);
  } else {
    return PlacePicker.pickPlace();
  }
}
