import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Beta Faz 4 — release imzalama (yayın engeli B1) ─────────────────────────────────────────────
//
// İmzalama gizli değerleri `android/key.properties` dosyasından okunur. O dosya ve anahtar deposu
// (`*.jks`) **Git'e girmez** — `android/.gitignore` bunu zorluyor. Şablon:
// `android/release-keystore.properties.example`.
//
// KURAL: release derlemesi **asla sessizce debug anahtarına düşmez**. Anahtar yoksa yapılandırma
// başarılı olur (debug derlemeleri ve CI çalışmaya devam eder) ama bir release artefaktı
// istendiğinde derleme **anlaşılır bir hatayla durur** — aşağıdaki taskGraph kontrolü.
// Gerekçe: debug anahtarıyla imzalanmış bir AAB'yi Play kabul etmez; sessiz bir geri düşüş,
// hatanın ancak yükleme anında fark edilmesine yol açardı.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

fun keystoreValue(name: String): String? = keystoreProperties.getProperty(name)?.trim()?.ifEmpty { null }

val keystoreFile: File? = keystoreValue("storeFile")?.let { rootProject.file(it) }

/** Dört alan da dolu ve anahtar deposu gerçekten diskte mi? */
val hasReleaseSigning: Boolean =
    keystoreFile?.exists() == true &&
        keystoreValue("storePassword") != null &&
        keystoreValue("keyAlias") != null &&
        keystoreValue("keyPassword") != null

android {
    namespace = "com.ehliyetegitim.ehliyet_akademi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (zonedSchedule) requires core library desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Play'e ilk yüklemeden sonra DEĞİŞTİRİLEMEZ.
        applicationId = "com.ehliyetegitim.ehliyet_akademi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = keystoreFile
                storePassword = keystoreValue("storePassword")
                keyAlias = keystoreValue("keyAlias")
                keyPassword = keystoreValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Anahtar yoksa BİLİNÇLİ olarak null bırakılır; debug anahtarına düşülmez.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
        }
    }
}

// Anahtar yokken bir release artefaktı istenirse derlemeyi burada, açık bir mesajla durdur.
// (Yapılandırma aşamasında fırlatılsaydı `flutter build apk --debug` ve CI da kırılırdı.)
if (!hasReleaseSigning) {
    gradle.taskGraph.whenReady {
        val wantsReleaseArtifact = allTasks.any { task ->
            task.name.contains("Release") &&
                listOf("assemble", "bundle", "package").any { task.name.startsWith(it) }
        }
        if (wantsReleaseArtifact) {
            throw GradleException(
                buildString {
                    appendLine("Release imzalama yapılandırılmamış — derleme durduruldu.")
                    appendLine()
                    appendLine("Beklenen dosya: ${keystorePropertiesFile.absolutePath}")
                    appendLine("Şablon:         android/release-keystore.properties.example")
                    appendLine("Anlatım:        PLAY_CONSOLE_SETUP.md §2")
                    if (keystorePropertiesFile.exists() && keystoreFile?.exists() != true) {
                        appendLine()
                        appendLine("key.properties var, ancak storeFile diskte bulunamadı:")
                        appendLine("  ${keystoreFile?.absolutePath ?: "(storeFile satırı boş)"}")
                    }
                    appendLine()
                    append("Debug anahtarına DÜŞÜLMEZ: Google Play debug anahtarıyla imzalanmış bir yapıyı kabul etmez.")
                }
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
