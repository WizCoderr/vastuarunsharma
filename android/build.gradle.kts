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
}

// payu_checkoutpro_flutter (and similar plugins) still declare compileSdk 31.
// Force Android modules to match the app so AAR metadata checks pass.
subprojects {
    fun Project.forceCompileSdk(version: Int) {
        if (!plugins.hasPlugin("com.android.library") &&
            !plugins.hasPlugin("com.android.application")
        ) {
            return
        }

        val androidExt = extensions.findByName("android") ?: return
        val setter =
            androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdkVersion" &&
                    it.parameterTypes.size == 1 &&
                    it.parameterTypes[0] == Int::class.javaPrimitiveType
            } ?: androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdk" &&
                    it.parameterTypes.size == 1 &&
                    it.parameterTypes[0] == Int::class.javaPrimitiveType
            }
        setter?.invoke(androidExt, version)
    }

    // evaluationDependsOn(":app") can already evaluate some projects.
    if (state.executed) {
        forceCompileSdk(37)
    } else {
        afterEvaluate {
            forceCompileSdk(37)
        }
    }
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
        options.compilerArgs.add("-Xlint:-deprecation")
        options.compilerArgs.add("-Xlint:-unchecked")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
