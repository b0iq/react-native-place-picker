import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type { PlacePickerOptions, PlacePickerResults } from './interfaces';

export interface Spec extends TurboModule {
  pickPlace(options?: PlacePickerOptions): Promise<PlacePickerResults>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('PlacePicker');
