import * as FirebaseApp from 'expo-firebase-app';

export const name = 'FirebaseApp';

const DEFAULT_APP_NAME = '__FIRAPP_DEFAULT';

export async function test({ describe, beforeAll, afterAll, it, expect }) {
  describe(name, () => {
    beforeAll(async () => {
      await FirebaseApp.initializeAppAsync();
    });

    afterAll(async () => {
      await FirebaseApp.initializeAppAsync();
    });

    describe('getAppAsync()', async () => {
      it(`returns default Firebase app`, async () => {
        let error = null;
        try {
          const app = await FirebaseApp.getAppAsync();
          expect(app.name).toBe(DEFAULT_APP_NAME);
        } catch (e) {
          error = e;
        }
        expect(error).toBeNull();
      });
    });

    describe('getAppsAsync()', async () => {
      it(`returns all Firebase apps`, async () => {
        let error = null;
        try {
          const apps = await FirebaseApp.getAppsAsync();
          expect(apps.length).toBe(1);
          expect(apps[0].name).toBe(DEFAULT_APP_NAME);
        } catch (e) {
          error = e;
        }
        expect(error).toBeNull();
      });
    });

    describe('deleteAsync()', async () => {
      it(`deleteAsync should succeed`, async () => {
        let error = null;
        try {
          const app = await FirebaseApp.getAppAsync();
          await app.deleteAsync();
        } catch (e) {
          error = e;
        }
        expect(error).toBeNull();
      });
      it(`default app should be gone`, async () => {
        let error = null;
        try {
          const app = await FirebaseApp.getAppAsync();
          expect(app).toBeNull();
        } catch (e) {
          error = e;
        }
        expect(error).not.toBeNull();
      });
      it(`getAppsAsync should no longer return the app`, async () => {
        let error = null;
        try {
          const apps = await FirebaseApp.getAppsAsync();
          expect(apps.length).toBe(0);
        } catch (e) {
          error = e;
        }
        expect(error).toBeNull();
      });
    });
  });
}
