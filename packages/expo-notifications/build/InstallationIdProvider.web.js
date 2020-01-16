import uuidv4 from 'uuid/v4';
const INSTALLATION_ID_KEY = '@@expo-notifications.InstallationId@@';
export default {
    getInstallationIdAsync: async () => {
        let installationId = localStorage.getItem(INSTALLATION_ID_KEY);
        if (installationId) {
            return installationId;
        }
        installationId = uuidv4();
        localStorage.setItem(INSTALLATION_ID_KEY, installationId);
        return installationId;
    },
    // mock implementations
    addListener: () => null,
    removeListeners: () => null,
};
//# sourceMappingURL=InstallationIdProvider.web.js.map