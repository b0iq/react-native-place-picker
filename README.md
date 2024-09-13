# react-native-place-picker

|         demo          |                                                             demo video                                                             |
| :-------------------: | :--------------------------------------------------------------------------------------------------------------------------------: |
| ![HEADER](HEADER.png) | <video src='https://github.com/b0iq/react-native-place-picker/assets/106549013/550551fd-5e25-40be-9b01-7698f4d48e2e' width='180'/> |

  <p align="center">
      <a href="https://badge.fury.io/js/react-native-place-picker">
      <img alt="NPM Version" src="https://badge.fury.io/js/react-native-place-picker.svg" />
    </a>
    <a href="https://github.com/b0iq/react-native-place-picker/actions">
      <img alt="Tests Passing" src="https://github.com/anuraghazra/github-readme-stats/workflows/Test/badge.svg" />
    </a>
    <a href="https://github.com/anuraghazra/github-readme-stats/graphs/contributors">
      <img alt="GitHub Contributors" src="https://img.shields.io/github/contributors/b0iq/react-native-place-picker" />
    </a>
    <a href="https://codecov.io/gh/b0iq/react-native-place-picker">
      <img src="https://codecov.io/gh/b0iq/react-native-place-picker/branch/master/graph/badge.svg" />
    </a>
    <a href="https://github.com/b0iq/react-native-place-picker/issues">
      <img alt="Issues" src="https://img.shields.io/github/issues/b0iq/react-native-place-picker?color=0088ff" />
    </a>
    <a href="https://github.com/b0iq/react-native-place-picker/pulls">
      <img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/b0iq/react-native-place-picker?color=0088ff" />
    </a>
    <br />
    <br />
  </p>

### Features

- [x] 🎨 Theme customization.
- [x] 📱 UI written natively.
- [x] 🗺️ Location reverse-geocoding (coordinate -> address).
- [x] 🔍 Searchable (users can search for location).
- [x] 📍 Device location.
- [x] ⚙️ Fully configurable.
- [x] 🏗️ Supporting Turbo Modules (New Arch) with backward compatibility.
- [x] ⚡ Renders on top of the app (Blazing Fast).
- [x] 📐 Well typed.
- [x] 📦 Significantly small package.
- [x] 🔗 No peer dependencies except React and React-Native <sup>[[1]](#extra)</sup>.

### How is it working?

> This plugin is built only by create native page `UIViewController` for iOS or `Activity` for Android. and present the page in front of React Native Application without any special dependencies just native code

## Installation

```sh
npm install react-native-place-picker
# or
yarn add react-native-place-picker
# or
pnpm add react-native-place-picker
# or
bun add react-native-place-picker
```

### Expo

- You need to add `expo-dev-client` and run `expo run:ios` or `expo run:android`

> **Info** Expo managed app not supported 🚧

### iOS

- If you want to enable user current location button you have to add this to your `Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>YOUR_PURPOSE_HERE</string>
```

### Android ⚠️

- Add to your `AndroidManifest.xml` you Google Map API Key or your application will crash

```xml
<meta-data
   android:name="com.google.android.geo.API_KEY"
   android:value="YOUR_KEY" />
```

### Request

```js
import { pickPlace } from "react-native-place-picker";

pickPlace({
  enableUserLocation: true,
  enableGeocoding: true,
  color: "#FF00FF",
  //...etc
})
  .then(console.log)
  .catch(console.log);

// or

pickPlace().then(console.log).catch(console.log);
```

### Result

```ts

{
    /**
     * @description Selected coordinate.
     */
    coordinate: PlacePickerCoordinate;
    /**
     * @description Geocoded address for selected location.
     * @if `enableGeocoding: true`
     */
    address?: PlacePickerAddress;
    /**
     * @description Did cancel the place picker window without selecting.
     */
    didCancel: boolean;
}

```

### PlacePickerOptions

| Property             | Type                                     | Description                                                                           | Default                                     |
| -------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------- |
| `presentationStyle`  | `PlacePickerPresentationStyle` \| string | Presentation style of the place picker window. **iOS only**                           | `'fullscreen'`                              |
| `title`              | `string`                                 | The title of the place picker window.                                                 | `'Choose Place'`                            |
| `searchPlaceholder`  | `string`                                 | Placeholder for the search bar in the place picker window.                            | `'Search...'`                               |
| `color`              | `string`                                 | Primary color of the theme (map pin, shadow, etc.).                                   | `'#FF0000'`                                 |
| `contrastColor`      | `string`                                 | Contrast color for the primary color.                                                 | `'#FFFFFF'`                                 |
| `locale`             | `string`                                 | Locale for the returned address.                                                      | `'en-US'`                                   |
| `initialCoordinates` | `PlacePickerCoordinate`                  | Initial map position.                                                                 | `{ latitude: 25.2048, longitude: 55.2708 }` |
| `enableGeocoding`    | `boolean`                                | geocoding for the selected address.                                                   | `true`                                      |
| `enableSearch`       | `boolean`                                | search bar for searching specific positions.                                          | `true`                                      |
| `enableUserLocation` | `boolean`                                | current user position button. Requires setup.                                         | `true`                                      |
| `enableLargeTitle`   | `boolean`                                | large navigation bar title of the UIViewController. **iOS only**                      | `true`                                      |
| `rejectOnCancel`     | `boolean`                                | Reject and return nothing if the user dismisses the window without selecting a place. | `true`                                      |

### PlacePickerPresentationStyle

| Enum Value   | Description                            |
| ------------ | -------------------------------------- |
| `modal`      | Presentation style as a modal window.  |
| `fullscreen` | Presentation style in fullscreen mode. |

### PlacePickerAddress

| Property     | Type     | Description                 |
| ------------ | -------- | --------------------------- |
| `name`       | `string` | Name of the location.       |
| `streetName` | `string` | Street name of the address. |
| `city`       | `string` | City of the address.        |
| `state`      | `string` | State of the address.       |
| `zipCode`    | `string` | Zip code of the address.    |
| `country`    | `string` | Country of the address.     |

### PlacePickerCoordinate

| Property    | Type     | Description                |
| ----------- | -------- | -------------------------- |
| `latitude`  | `number` | Latitude of the location.  |
| `longitude` | `number` | Longitude of the location. |

### PlacePickerResults

| Property     | Type                    | Description                                                    |
| ------------ | ----------------------- | -------------------------------------------------------------- |
| `coordinate` | `PlacePickerCoordinate` | Selected coordinate.                                           |
| `address`    | `PlacePickerAddress`    | Geocoded address for selected location (if `enableGeocoding`). |
| `didCancel`  | `boolean`               | Indicates if the place picker was canceled without selecting.  |

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
