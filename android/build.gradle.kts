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
subprojects {
    project.evaluationDependsOn(":app")
    if (name == "network_info_plus") {
        // This pinned plugin declares SDK 33, below its AndroidX requirements.
        // Override in the project, never in the machine-wide Pub cache.
        pluginManager.withPlugin("com.android.library") {
            extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
                finalizeDsl { library ->
                    library.compileSdk = project(":app")
                        .extensions.getByType<com.android.build.api.dsl.ApplicationExtension>()
                        .compileSdk
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
