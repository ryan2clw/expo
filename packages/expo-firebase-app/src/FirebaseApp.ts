import { UnavailabilityError } from '@unimodules/core';
import ExpoFirebaseApp from './ExpoFirebaseApp';

class FirebaseApp {
  public readonly name: string;

  constructor(name: string) {
    this.name = name;
  }

  deleteAsync(): Promise<void> {
    // @ts-ignore
    if (!ExpoFirebaseApp.deleteAppAsync) {
      throw new UnavailabilityError('expo-firebase-app', 'deleteAppAsync');
    }
    // @ts-ignore
    return ExpoFirebaseApp.deleteAppAsync(this.name);
  }

  getOptionsAsync(): Promise<any> {
    // @ts-ignore
    if (!ExpoFirebaseApp.getAppOptionsAsync) {
      throw new UnavailabilityError('expo-firebase-app', 'getAppOptionsAsync');
    }
    // @ts-ignore
    return ExpoFirebaseApp.getAppOptionsAsync(this.name);
  }
}

/**
 * Similar to `firebase.initializeApp()` on web but works to start a native Firebase app while the app is running.
 * This can be used to test the native iOS Firebase app in the Expo client.
 * This method should not be used in production, instead the app should be bundled with the native Google Services files via the `app.json`.
 *
 * @param googleServices Platform specific Google Services file for starting a Firebase app during runtime
 */
export async function initializeAppAsync(options?: any, name?: string): Promise<FirebaseApp> {
  // @ts-ignore
  if (!ExpoFirebaseApp.initializeAppAsync) {
    throw new UnavailabilityError('expo-firebase-app', 'initializeAppAsync');
  }
  // @ts-ignore
  const appName = await ExpoFirebaseApp.initializeAppAsync(options, name);
  return new FirebaseApp(appName);
}

export async function getAppAsync(name?: string): Promise<FirebaseApp> {
  // @ts-ignore
  if (!ExpoFirebaseApp.getAppAsync) {
    throw new UnavailabilityError('expo-firebase-app', 'getAppAsync');
  }
  // @ts-ignore
  const appName = await ExpoFirebaseApp.getAppAsync(name);
  return new FirebaseApp(appName);
}

export async function getAppsAsync(): Promise<FirebaseApp[]> {
  // @ts-ignore
  if (!ExpoFirebaseApp.getAppsAsync) {
    throw new UnavailabilityError('expo-firebase-app', 'getAppsAsync');
  }
  // @ts-ignore
  const appNames = await ExpoFirebaseApp.getAppsAsync();
  return appNames.map(appName => new FirebaseApp(appName));
}

/**
 * Delete a running Firebase app instance. Only works for the default app. If no default app is running then nothing happens.
 *
 * @param googleServices Platform specific Google Services file.
 */
