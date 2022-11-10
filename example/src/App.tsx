import * as React from 'react';

import { StyleSheet, View, Button, StatusBar } from 'react-native';
import { pickPlace } from 'react-native-place-picker';

export default function App() {
  const pressHandlerWithOptions = () => {
    pickPlace({
      title: 'Choose Place',
      initialCoordinates: {
        latitude: 25.2048,
        longitude: 55.2708,
      },
    })
      .then(console.log)
      .catch(console.log);
  };

  const pressHandler = () => {
    pickPlace().then(console.log).catch(console.log);
  };

  return (
    <>
      <StatusBar barStyle={'default'} />
      <View style={styles.container}>
        <Button
          title="Pick place with options"
          onPress={pressHandlerWithOptions}
        />
        <Button title="Pick place" onPress={pressHandler} />
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
