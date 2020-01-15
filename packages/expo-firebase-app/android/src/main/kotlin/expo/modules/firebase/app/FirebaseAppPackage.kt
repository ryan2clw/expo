package expo.modules.firebase.app

import android.content.Context

import org.unimodules.core.BasePackage
import org.unimodules.core.ExportedModule
import org.unimodules.core.ViewManager

class FirebaseAppPackage : BasePackage() {
  override fun createExportedModules(context: Context): List<ExportedModule> {
    return listOf(FirebaseAppModule(context) as ExportedModule)
  }

}
