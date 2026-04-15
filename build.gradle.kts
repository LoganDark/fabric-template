@file:Suppress("PropertyName")

val minecraft_version: String by project
val yarn_mappings: String by project
val loader_version: String by project
val fabric_api_version: String by project

val mod_group: String by project
val mod_package: String by project
val mod_class: String by project
val mod_id: String by project
val mod_name: String by project
val mod_version: String by project
val mod_description: String by project

val mod_full_package = "${mod_group}.${mod_package}"

plugins {
	id("fabric-loom")
	`maven-publish`
}

group = mod_group
version = mod_version

repositories {
	maven {
		name = "LocalMaven"
		url = uri("file://${System.getProperty("user.home")}/maven")
	}

	mavenCentral()
}

sourceSets.main {
	java.srcDir("build/generated/sources/mod/java")
}

val generateModSources by tasks.registering {
	val templateDir = file("src/main/java/TEMPLATE_PACKAGE")
	val outputDir = layout.buildDirectory.dir("generated/sources/mod/java")

	inputs.dir(templateDir)
	inputs.property("mod_full_package", mod_full_package)
	inputs.property("mod_class", mod_class)
	inputs.property("mod_id", mod_id)
	outputs.dir(outputDir)

	doLast {
		val outBase = outputDir.get().asFile
		val packageDir = File(outBase, mod_full_package.replace('.', '/'))

		outBase.deleteRecursively()
		packageDir.mkdirs()

		templateDir.walkTopDown().filter { it.isFile && it.extension == "java" }.forEach { file ->
			val relativePath = file.relativeTo(templateDir)
			var content = file.readText()
				.replace("TEMPLATE_PACKAGE", mod_full_package)
				.replace("TEMPLATE_CLASSNAME", mod_class)
				.replace("TEMPLATE_MODID", mod_id)

			var fileName = relativePath.path
				.replace("TEMPLATE_CLASSNAME", mod_class)

			val targetFile = File(packageDir, fileName)
			targetFile.parentFile.mkdirs()
			targetFile.writeText(content)
		}
	}
}

tasks.compileJava {
	dependsOn(generateModSources)
}

tasks.processResources {
	val props = mapOf(
		"mod_id" to mod_id,
		"mod_name" to mod_name,
		"mod_version" to mod_version,
		"mod_class" to mod_class,
		"mod_description" to mod_description,
		"mod_full_package" to mod_full_package,
	)

	inputs.properties(props)

	filesMatching(listOf("fabric.mod.json", "*.mixins.json")) {
		expand(props)
	}

	rename("TEMPLATE_MODID\\.(.*\\.)*mixins\\.json", "${mod_id}.$1mixins.json")

	doLast {
		destinationDir.walkTopDown()
			.filter { it.name == "fabric.mod.json" || it.name.endsWith(".mixins.json") }
			.forEach { file ->
				file.writeText(
					file.readText()
						.replace("TEMPLATE_PACKAGE", mod_full_package)
						.replace("TEMPLATE_CLASSNAME", mod_class)
					.replace("TEMPLATE_MODID", mod_id)
				)
			}

		for (dirName in listOf("data", "assets")) {
			val dir = File(destinationDir, dirName)
			if (dir.isDirectory) {
				dir.walkTopDown()
					.filter { it.isFile && it.extension == "json" }
					.forEach { file ->
						val text = file.readText()
						val replaced = text.replace("TEMPLATE_MODID", mod_id)
						if (replaced !== text) file.writeText(replaced)
					}
			}
		}

		destinationDir.walkTopDown()
			.filter { it.isDirectory && it.name == "TEMPLATE_MODID" }
			.sortedByDescending { it.path.length }
			.forEach { dir -> dir.renameTo(File(dir.parentFile, mod_id)) }
	}
}

tasks.jar {
	exclude("TEMPLATE_PACKAGE/**")
}

dependencies {
	minecraft("com.mojang:minecraft:${minecraft_version}")
	mappings("net.fabricmc:yarn:${yarn_mappings}")
	modImplementation("net.fabricmc:fabric-loader:${loader_version}")
	modImplementation("net.fabricmc:fabric:${fabric_api_version}")
}

loom {
	runConfigs.named("server") {
		runDir = "run_server"
	}
}

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(21)
	}

	withSourcesJar()
}

tasks.named<Jar>("sourcesJar") {
	dependsOn(tasks.processResources, generateModSources)
	exclude("TEMPLATE_PACKAGE/**")

	val rawResourceDirs = sourceSets.main.get().resources.srcDirs.map { it.absoluteFile }
	exclude { element ->
		val f = element.file.absoluteFile
		rawResourceDirs.any { f.startsWith(it) }
	}

	from(tasks.processResources)
}

publishing {
	publications {
		create<MavenPublication>("mod") {
			artifactId = mod_id
			from(components["java"])
		}
	}

	repositories {
		maven {
			name = "LocalMaven"
			url = uri("file://${System.getProperty("user.home")}/maven")
		}
	}
}

afterEvaluate {
	tasks.findByName("ideaSyncTask")?.doFirst {
		val configDir = file(".idea/runConfigurations")
		configDir.resolve("Minecraft_Client.xml").delete()
		configDir.resolve("Minecraft_Server.xml").delete()
	}
}

