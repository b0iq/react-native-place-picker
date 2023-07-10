# react-native-place-picker


demo | demo video
:-: | :-:
![HEADER](HEADER.png) | <video src='https://github.com/b0iq/react-native-place-picker/assets/106549013/550551fd-5e25-40be-9b01-7698f4d48e2e' width=180/>


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

- [x] Theme customization.
- [x] UI written natively.
- [x] Location reverse-geocoding (coordinate -> address).
- [x] Searchable (users can search for location).
- [x] Device location.
- [x] Fully configurable. 
- [x] Supporting Turbo Modules (New Arch) with backward capability.
- [x] Renders on top of the app (Blazing Fast).
- [x] Well typed.
- [x] Significantly small package.
- [x] No peer depedancies except React and React-Native <sup>[[1]](#extra) </sup> 

### How is it working?

> This plugin is built only by create native page `UIViewController` for iOS or `Activity` for Android. and present the page in front of React Native Application without any special dependencies just native code

## Installation

```sh
npm install react-native-place-picker
# or
yarn add react-native-place-picker
```

### Expo

- You need to add `expo-dev-client` and run `expo run:ios` or `expo run:android`

> **Info** Expo managed app not yet supported 🚧

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

## Usage
# [Checkout the documentation](https://b0iq.github.io/react-native-place-picker)
### Request

```js
import { pickPlace } from 'react-native-place-picker';

pickPlace({
  enableUserLocation: true,
  enableGeocoding: true,
  color: '#FF00FF',
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

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

## Extra
[1] The only liberary is used: Kotlin object parsing liberary `com.fasterxml.jackson.module:jackson-module-kotlin:2.14.+` to parse Javascript parameters easily.
