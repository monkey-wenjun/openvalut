if (System.getProperty("design.codeux.ndkVersion") == null) {
//    println("Setting ndkVersion")
    if (rootProject.hasProperty("design.codeux.ndkVersion")) {
        System.setProperty("design.codeux.ndkVersion", rootProject.property("design.codeux.ndkVersion").toString())
    } else {
        System.setProperty("design.codeux.ndkVersion", "28.2.13676358")
    }
}
println("ndkVersion: ${System.getProperty("design.codeux.ndkVersion")}")

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(File("../build"))
subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.get().dir(project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
    if (project.path == ":file_picker_writable" || project.path == ":flutter_email_sender") {
        apply(plugin = "com.android.library")
        apply(plugin = "kotlin-android")
        project.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
            jvmToolchain(17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory.get())
}
