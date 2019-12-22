package expo.modules.updates;

import android.content.Context;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

import org.unimodules.core.ExportedModule;
import org.unimodules.core.ModuleRegistry;
import org.unimodules.core.Promise;
import org.unimodules.core.interfaces.ExpoMethod;

import expo.modules.updates.db.UpdatesDatabase;
import expo.modules.updates.db.entity.UpdateEntity;
import expo.modules.updates.loader.FileDownloader;
import expo.modules.updates.loader.Manifest;
import expo.modules.updates.loader.RemoteLoader;

public class UpdatesModule extends ExportedModule {
  private static final String NAME = "ExpoUpdates";
  private static final String TAG = UpdatesModule.class.getSimpleName();

  private ModuleRegistry mModuleRegistry;
  private Context mContext;

  public UpdatesModule(Context context) {
    super(context);
    mContext = context;
  }

  @Override
  public String getName() {
    return NAME;
  }

  @Override
  public void onCreate(ModuleRegistry moduleRegistry) {
    mModuleRegistry = moduleRegistry;
  }

  @Override
  public Map<String, Object> getConstants() {
    Map<String, Object> constants = new HashMap<>();
    constants.put("localAssets", UpdatesController.getInstance().getLocalAssetFiles());

    return constants;
  }

  @ExpoMethod
  public void reload(final Promise promise) {
    if (UpdatesController.getInstance().reloadReactApplication()) {
      promise.resolve(null);
    } else {
      promise.reject(
          "ERR_UPDATES_RELOAD",
          "Could not reload application. Ensure you have passed an instance of ReactApplication into UpdatesController.initialize()."
      );
    }
  }

  @ExpoMethod
  public void checkForUpdateAsync(final Promise promise) {
    final UpdatesController controller = UpdatesController.getInstance();

    if (controller == null) {
      promise.reject(
          "ERR_UPDATES_CHECK",
          "The updates module controller has not been properly initialized. If you're in development mode, you cannot check for updates. Otherwise, make sure you have called UpdatesController.initialize()."
      );
      return;
    }

    FileDownloader.downloadManifest(controller.getManifestUrl(), mContext, new FileDownloader.ManifestDownloadCallback() {
      @Override
      public void onFailure(String message, Exception e) {
        promise.reject("ERR_UPDATES_CHECK", message, e);
        Log.e(TAG, message, e);
      }

      @Override
      public void onSuccess(Manifest manifest) {
        UpdateEntity launchedUpdate = controller.getLaunchedUpdate();
        if (launchedUpdate == null) {
          // this shouldn't ever happen, but if we don't have anything to compare
          // the new manifest to, let the user know an update is available
          promise.resolve(manifest.getRawManifestJson().toString());
          return;
        }

        if (new SelectionPolicyNewest().shouldLoadNewUpdate(manifest.getUpdateEntity(), launchedUpdate)) {
          promise.resolve(manifest.getRawManifestJson().toString());
        } else {
          promise.resolve(false);
        }
      }
    });
  }

  @ExpoMethod
  public void fetchUpdateAsync(final Promise promise) {
    final UpdatesController controller = UpdatesController.getInstance();

    if (controller == null) {
      promise.reject(
          "ERR_UPDATES_FETCH",
          "The updates module controller has not been properly initialized. If you're in development mode, you cannot fetch updates. Otherwise, make sure you have called UpdatesController.initialize()."
      );
      return;
    }

    UpdatesDatabase database = controller.getDatabase();
    new RemoteLoader(mContext, database, controller.getUpdatesDirectory())
        .start(
            controller.getManifestUrl(),
            new RemoteLoader.LoaderCallback() {
              @Override
              public void onFailure(Exception e) {
                controller.releaseDatabase();
                promise.reject("ERR_UPDATES_FETCH", "Failed to download new update", e);
              }

              @Override
              public boolean onManifestDownloaded(Manifest manifest) {
                UpdateEntity launchedUpdate = controller.getLaunchedUpdate();
                if (launchedUpdate == null) {
                  // this shouldn't ever happen, but if we don't have anything to compare
                  // the new manifest to, let the user know an update is available
                  return true;
                }
                return new SelectionPolicyNewest().shouldLoadNewUpdate(manifest.getUpdateEntity(), launchedUpdate);
              }

              @Override
              public void onSuccess(UpdateEntity update) {
                controller.releaseDatabase();
                promise.resolve(update == null ? false : update.metadata.toString());
              }
            }
        );
  }
}
