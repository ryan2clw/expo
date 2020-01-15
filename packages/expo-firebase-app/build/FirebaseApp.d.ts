declare class FirebaseApp {
    readonly name: string;
    constructor(name: string);
    deleteAsync(): Promise<void>;
    getOptionsAsync(): Promise<any>;
}
/**
 * Similar to `firebase.initializeApp()` on web but works to start a native Firebase app while the app is running.
 * This can be used to test the native iOS Firebase app in the Expo client.
 * This method should not be used in production, instead the app should be bundled with the native Google Services files via the `app.json`.
 *
 * @param googleServices Platform specific Google Services file for starting a Firebase app during runtime
 */
export declare function initializeAppAsync(options?: any, name?: string): Promise<FirebaseApp>;
export declare function getAppAsync(name?: string): Promise<FirebaseApp>;
export declare function getAppsAsync(): Promise<FirebaseApp[]>;
export {};
/**
 * Delete a running Firebase app instance. Only works for the default app. If no default app is running then nothing happens.
 *
 * @param googleServices Platform specific Google Services file.
 */
