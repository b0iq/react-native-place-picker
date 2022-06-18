# react-native-place-picker

Pick any place with single click

## Installation

```sh
npm install react-native-place-picker
# or
yarn add react-native-place-picker
```

## Usage

```js
import { pickPlace } from 'react-native-place-picker';

const OPTIONS = {
    title: "Choose Place",
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

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
