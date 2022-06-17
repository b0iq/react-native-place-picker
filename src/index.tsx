import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-place-picker' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

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

/**
 *
 * @param {Number} a
 * @returns {Number}
 */
export function sqrt(a: number): Promise<number> {
  return PlacePicker.sqrt(a);
}
/**
 *
 * @param {Number} a
 * @param {Number} b
 * @returns {number} results
 */
export function multiply(a: number, b: number): Promise<number> {
  return PlacePicker.multiply(a, b);
}
