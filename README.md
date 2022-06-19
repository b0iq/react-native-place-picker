# react-native-place-picker
Pick any place with single click 🚀

⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️

Don't forget to ***STAR AND FORK*** this repo if you like it

⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️

![HEADER](HEADER.png)


### How is it working?
> This plugin is built only by create native page `UIViewController` for iOS or `Activity` for Android. and present the page in front of React Native Application without any special dependencies just native code

## Installation

```sh
npm install react-native-place-picker
# or
yarn add react-native-place-picker
```

### Expo

* You need to add `expo-dev-client` and run `expo run:ios` or `expo run:android` 

> **Info** Expo managed app not yet supported 🚧

### iOS

* No further steps needed 😁

### Android ⚠️

* Add to your `AndroidManifest.xml` you Google Map API Key or your application will crash

```xml
<meta-data
   android:name="com.google.android.geo.API_KEY"
   android:value="YOUR_KEY" />
```

## Usage

### Request
```js
import { pickPlace } from 'react-native-place-picker';

const OPTIONS = {

    title: "Choose Place", // Modal title

    // Initial map location coordinates
    initialCoordinates: {
        latitude: 25.2048,
        longitude: 55.2708
    }

};

pickPlace(OPTIONS)
    .then(console.log)
    .catch(console.log)

// or

pickPlace().then(console.log).catch(console.log)

```

### Result

```ts

{
    // Determine if user did cancel th operation
    canceled: boolean,
    // Coordinates values
    latitude: number,
    longitude: number,
}

```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
