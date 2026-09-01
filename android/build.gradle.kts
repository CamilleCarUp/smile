allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// --- compileSdk-Angleichung fuer Plugin-Subprojekte -------------------------
// Problem: manche Flutter-Plugins kompilieren ihr Android-Modul noch gegen
// eine aeltere API-Version, als ihre eigenen Abhaengigkeiten verlangen.
// Konkret: flutter_plugin_android_lifecycle fordert compileSdk >= 36,
// file_picker selbst steht noch auf 34 -> Build bricht ab ("checkDebugAarMetadata").
// Betrifft potenziell auch image_picker und pdfx, die dieselbe Abhaengigkeit
// mitbringen.
//
// Bewusst per Reflection statt ueber AGP-Typen, damit es unabhaengig von der
// Android-Gradle-Plugin-Version funktioniert (die DSL-Interfaces aendern
// zwischen AGP-Majorversionen ihre Signatur).
//
// Muss VOR dem evaluationDependsOn-Block weiter unten stehen: sonst sind
// einzelne Subprojekte bereits fertig evaluiert, und afterEvaluate wirft
// "Cannot run Project.afterEvaluate(Action) when the project is already evaluated".
//
// Kann entfernt werden, sobald alle verwendeten Plugins selbst gegen
// mindestens diese API-Version kompilieren.
fun raiseCompileSdk(project: Project, required: Int) {
    val androidExtension = project.extensions.findByName("android") ?: return
    val getter = androidExtension.javaClass.methods
        .firstOrNull { it.name == "getCompileSdk" && it.parameterCount == 0 }
    val setter = androidExtension.javaClass.methods
        .firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
    val current = runCatching { getter?.invoke(androidExtension) as? Int }.getOrNull()
    if (setter != null && (current == null || current < required)) {
        runCatching { setter.invoke(androidExtension, required) }
            .onSuccess { println("compileSdk fuer ${project.name}: ${current ?: "unbekannt"} -> $required") }
    }
}

subprojects {
    if (state.executed) {
        raiseCompileSdk(project, 36)
    } else {
        afterEvaluate { raiseCompileSdk(project, 36) }
    }
}
// ---------------------------------------------------------------------------

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
