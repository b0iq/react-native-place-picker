import React, { useCallback, useState } from 'react';

import { StyleSheet, Text, ScrollView, Alert } from 'react-native';
import {
  pickPlace,
  PlacePickerOptions,
  PlacePickerResults,
} from 'react-native-place-picker';
import { Button } from './Components/Button';
import { Row } from './Components/Row';
// @ts-ignore
import { version as coreVersion } from 'react-native/Libraries/Core/ReactNativeVersion';
function getReactNativeVersion() {
  const version = `${coreVersion.major}.${coreVersion.minor}.${coreVersion.patch}`;
  return coreVersion.prerelease
    ? version + `-${coreVersion.prerelease}`
    : version;
}

function isTMActive() {
  // @ts-ignore
  return global.__turboModuleProxy != null;
}

export default function App(props: any) {
  const [isFabric, setFabric] = useState(false);
  const onLayout = useCallback(
    (ev) => {
      setFabric(
        Boolean(ev.currentTarget._internalInstanceHandle?.stateNode?.canonical)
      );
    },
    [setFabric]
  );

  const [isTM] = useState(isTMActive());

  const [results, setResults] = useState<PlacePickerResults>();
  const [options, setOptions] = useState<PlacePickerOptions>({
    presentationStyle: 'fullscreen',
    contrastColor: '#FFFFFF',
    color: '#FF0000',
    searchPlaceholder: 'Search...',
    title: 'Choose Place',
    enableGeocoding: true,
    enableSearch: true,
    enableUserLocation: true,
    enableLargeTitle: true,
    rejectOnCancel: true,
    locale: 'en-US',
    initialCoordinates: {
      latitude: 25.2048,
      longitude: 55.2708,
    },
  });
  const pressHandlerWithOptions = () => {
    pickPlace(options)
      .then(setResults)
      .catch((error) => {
        console.log(error);
        setResults(undefined);
      });
  };

  const pressHandler = () => {
    pickPlace()
      .then(setResults)
      .catch((error) => {
        console.log(error);
        setResults(undefined);
      });
  };

  return (
    <ScrollView
      onLayout={onLayout}
      contentInsetAdjustmentBehavior="automatic"
      style={styles.scrollView}
      contentContainerStyle={styles.container}
    >
      <Text style={styles.title}>Place Picker Playground</Text>
      <Text style={styles.subtitle}>{'(Click to edit)'}</Text>
      <Row
        label="Presentation Style"
        value={
          (options.presentationStyle?.charAt(0)?.toUpperCase() || '') +
          options.presentationStyle?.slice(1)
        }
        onPress={() => {
          setOptions((prev) => ({
            ...prev,
            presentationStyle:
              prev.presentationStyle === 'modal' ? 'fullscreen' : 'modal',
          }));
        }}
      />
      <Row
        label="Contrast Color"
        color={options.contrastColor}
        contrast={options.color}
        value={options.contrastColor}
        onPress={() => {
          Alert.prompt(
            'Contrast Color',
            'Enter color hex value with #',
            (text) => {
              setOptions((prev) => ({
                ...prev,
                contrastColor: text,
              }));
            },
            'plain-text',
            options.contrastColor
          );
        }}
      />
      <Row
        label="Color"
        color={options.color}
        contrast={options.contrastColor}
        value={options.color}
        onPress={() => {
          Alert.prompt(
            'Color',
            'Enter color hex value with #',
            (text) => {
              setOptions((prev) => ({
                ...prev,
                color: text,
              }));
            },
            'plain-text',
            options.color
          );
        }}
      />
      <Row
        label="Title"
        value={options.title}
        onPress={() => {
          Alert.prompt(
            'Title',
            'Enter a new title',
            (text) => {
              setOptions((prev) => ({
                ...prev,
                title: text,
              }));
            },
            'plain-text',
            options.title
          );
        }}
      />
      <Row
        label="Search Placeholder"
        value={options.searchPlaceholder}
        onPress={() => {
          Alert.prompt(
            'Search Placeholder',
            'Enter a new search placeholder',
            (text) => {
              setOptions((prev) => ({
                ...prev,
                searchPlaceholder: text,
              }));
            },
            'plain-text',
            options.searchPlaceholder
          );
        }}
      />
      <Row
        label="Locale"
        value={options.locale}
        onPress={() => {
          Alert.prompt(
            'Locale',
            'Enter a new locale',
            (text) => {
              setOptions((prev) => ({
                ...prev,
                locale: text,
              }));
            },
            'plain-text',
            options.locale
          );
        }}
      />
      <Row
        label="Initial Coordinates"
        value={`[${options.initialCoordinates?.latitude.toFixed(
          5
        )}, ${options.initialCoordinates?.longitude.toFixed(5)}]`}
        onPress={() => {
          pickPlace({
            presentationStyle: 'modal',
            searchPlaceholder: 'Search...',
            title: 'Set initial coordinates',
            enableLargeTitle: false,
            enableSearch: false,
            enableGeocoding: false,
          })
            .then((r) => {
              setOptions((prev) => ({
                ...prev,
                initialCoordinates: r.coordinate,
              }));
            })
            .catch(console.log);
        }}
      />
      <Row
        label="Enable Geocoding"
        value={String(options.enableGeocoding)}
        onPress={() => {
          setOptions((prev) => ({
            ...prev,
            enableGeocoding: !prev.enableGeocoding,
          }));
        }}
      />
      <Row
        label="Enable Search"
        value={String(options.enableSearch)}
        onPress={() => {
          setOptions((prev) => ({
            ...prev,
            enableSearch: !prev.enableSearch,
          }));
        }}
      />
      <Row
        label="Enable User Location"
        value={String(options.enableUserLocation)}
        onPress={() => {
          setOptions((prev) => ({
            ...prev,
            enableUserLocation: !prev.enableUserLocation,
          }));
        }}
      />
      <Row
        label="Enable Large Title"
        value={String(options.enableLargeTitle)}
        onPress={() => {
          setOptions((prev) => ({
            ...prev,
            enableLargeTitle: !prev.enableLargeTitle,
          }));
        }}
      />
      <Row
        label="Reject on Cancel"
        value={String(options.rejectOnCancel)}
        onPress={() => {
          setOptions((prev) => ({
            ...prev,
            rejectOnCancel: !prev.rejectOnCancel,
          }));
        }}
      />
      <Button
        label="Pick Place with options"
        onPress={pressHandlerWithOptions}
      />
      <Button red label="Pick Place" onPress={pressHandler} />
      {results && (
        <>
          <Text style={styles.title}>Results:</Text>
          <Text style={styles.code}>{JSON.stringify(results, null, '\t')}</Text>
        </>
      )}

      <Text style={styles.title}>Debug Info:</Text>
      <Row label="React Native Version" value={getReactNativeVersion()} />
      <Row
        label="Hermes enabled"
        // @ts-ignore
        value={global.HermesInternal ? 'true' : 'false'}
      />
      <Row label="Turbo Modules" value={isTM ? 'true' : 'false'} />
      <Row label="Fabric" value={String(isFabric)} />
      <Row label="concurrentRoot" value={String(props.concurrentRoot)} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
  },
  container: {
    padding: 20,
    paddingTop: 70,
  },
  title: {
    fontSize: 25,
    fontWeight: '900',
    marginBottom: 5,
    textAlign: 'left',
  },
  subtitle: {
    fontSize: 15,
    fontWeight: '300',
    marginBottom: 20,
    textAlign: 'left',
  },
  code: {
    fontSize: 12,
    fontWeight: '300',
    marginBottom: 20,
    textAlign: 'left',
    color: '#666',
    fontFamily: 'Courier',
  },
});
