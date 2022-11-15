import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  pickPlace(options?: {
    /**
     * @description Presentation style of the place picker window on iOS.
     * @type PlacePickerPresentationStyle | string
     * @platform iOS only
     * @default PlacePickerPresentationStyle.fullscreen | 'fullscreen'
     */
    presentationStyle?: string;
    /**
     * @description The title of the place picker window.
     * @type string
     * @default 'Choose Place'
     */
    title?: string;
    /**
     * @description If enableSearch is true, the place picker window will have a search bar and you can set the placeholder of the text box.
     * @type string
     * @default 'Search...'
     */
    searchPlaceholder?: string;
    /**
     * @description Primary color of the theme such as map pin, shadow, etc.
     * @type string
     * @platform ios, android
     * @default '#FF0000'
     */
    color?: string;
    /**
     * @description The contrast color of the primary color.
     * @type string
     * @default '#FFFFFF'
     */
    contrastColor?: string;
    /**
     * @description The locale of returned address.
     * @type string
     * @platform ios, android
     * @default 'en-US'
     */
    locale?: string;
    /**
     * @description Initial map position.
     * @type PlacePickerCoordinate
     * @default `{latitude: 25.2048, longitude: 55.2708 }`
     */
    initialCoordinates?: {
      latitude: number;
      longitude: number;
    };
    /**
     * @description Enable to geocode the address of the selected place.
     * @type boolean
     * @default true
     */
    enableGeocoding?: boolean;
    /**
     * @description Enable to the search bar to let user search for certain position.
     * @type boolean
     * @default true
     */
    enableSearch?: boolean;
    /**
     * @description Enable current user position button.
     * @WARN You have to setup location privacy note into Info.plist for iOS and AndroidManifest.xml for Android.
     * @type boolean
     * @default true
     */
    enableUserLocation?: boolean;
    /**
     * @description Enable large navigation bar title of the UIViewController.
     * @type boolean
     * @platform iOS only
     * @default true
     */
    enableLargeTitle?: boolean;
    /**
     * @description Reject and return nothing if user dismiss the window.
     * @type boolean
     * @default true
     */
    rejectOnCancel?: boolean;
  }): Promise<{
    /**
     * @description Selected coordinate.
     */
    coordinate: {
      latitude: number;
      longitude: number;
    };
    /**
     * @description Geocoded address for selected location.
     * @if `enableGeocoding: true`
     */
    address?: {
      name: string;
      streetName: string;
      city: string;
      state: string;
      zipCode: string;
      country: string;
    };
    /**
     * @description Did cancel the place picker window without selecting.
     */
    didCancel: boolean;
  }>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('PlacePicker');
