import React from 'react';
import { TouchableOpacity, View, Text, StyleSheet } from 'react-native';

export const Button = ({
  label,
  red = false,
  onPress = () => {},
}: {
  label: string;
  red?: boolean;
  onPress?: () => void;
}) => (
  <TouchableOpacity onPress={onPress}>
    <View style={[styles.button, red && { backgroundColor: '#FF0000' }]}>
      <Text style={styles.buttonLabel}>{label}</Text>
    </View>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  button: {
    backgroundColor: '#007aff',
    padding: 10,
    borderRadius: 5,
    marginBottom: 5,
  },
  buttonLabel: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
});
