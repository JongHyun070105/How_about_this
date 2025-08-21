allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Kotlin DSL에서 Java import 문제를 방지하기 위한 설정
    afterEvaluate {
        // 프로젝트 평가 후에 실행되므로 import 문제가 해결됨
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}