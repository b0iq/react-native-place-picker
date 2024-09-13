/* eslint-disable react-native/no-inline-styles */
import React from 'react';
import { TouchableOpacity, View, Text, StyleSheet } from 'react-native';

export const Row = ({
  label,
  value,
  color,
  contrast = '#007aff',
  onPress,
}: {
  label: string;
  value?: string;
  color?: string;
  contrast?: string;
  onPress?: () => void;
}) => (
  <TouchableOpacity onPress={onPress?.bind(this)}>
    <View style={styles.row}>
      <Text style={styles.label}>{label}</Text>
      <Text
        style={[
          styles.value,
          {
            color: contrast,
            backgroundColor: color,
            borderColor: color ? '#000' : 'transparent',
            borderRadius: color ? 5 : undefined,
            overflow: color ? 'hidden' : undefined,
          },
        ]}
      >
        {value}
      </Text>
    </View>
  </TouchableOpacity>
);
const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 5,
    backgroundColor: '#F5F5F5',
    borderRadius: 5,
    marginBottom: 5,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
  },
  value: {
    fontSize: 16,
    fontWeight: '400',
    color: '#007aff',
    textAlign: 'right',
    padding: 5,
    borderWidth: 2,
  },
});
