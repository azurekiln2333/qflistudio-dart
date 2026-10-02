package com.azurekiln.qfli.dartwing

import android.content.Context
import android.system.ErrnoException
import android.system.Os
import android.system.OsConstants
import org.json.JSONObject
import java.io.DataInputStream
import java.io.File
import java.util.zip.ZipInputStream

internal class DartSdkRuntime(private val context: Context) {
    fun prepare(): Map<String, String> {
        val nativeDir = context.applicationInfo.nativeLibraryDir
        val vm = File(nativeDir, "libqfli_dartvm.so")
        val header = DataInputStream(vm.inputStream()).use { input ->
            ByteArray(20).also { input.readFully(it) }
        }
        check(header[0] == 0x7f.toByte() && header[1] == 'E'.code.toByte() &&
            header[2] == 'L'.code.toByte() && header[3] == 'F'.code.toByte() &&
            header[4] == 2.toByte() && header[5] == 1.toByte()) { "Invalid Android Dart VM" }
        val machine = (header[18].toInt() and 0xff) or ((header[19].toInt() and 0xff) shl 8)
        val abi = when (machine) {
            62 -> "x86_64"
            183 -> "arm64-v8a"
            else -> error("Unsupported Android Dart VM architecture: $machine")
        }
        val manifest = context.assets.open("dart-sdk-$abi.json").bufferedReader().use {
            JSONObject(it.readText())
        }
        check(manifest.getInt("version") == 1) { "Unsupported Android Dart SDK layout" }
        val home = File(context.filesDir, "dart-sdk")
        val marker = File(home, ".qfli-sdk-id")
        val id = manifest.getString("id")
        if (!marker.isFile || marker.readText() != id || !File(home, "lib/core/core.dart").isFile) {
            val staging = File(context.filesDir, "dart-sdk-install")
            staging.deleteRecursively()
            check(staging.mkdirs()) { "Cannot create Android Dart SDK directory" }
            try {
                ZipInputStream(context.assets.open("dart-sdk-$abi.zip")).use { zip ->
                    var entry = zip.nextEntry
                    while (entry != null) {
                        val file = File(staging, entry.name)
                        check(file.canonicalPath.startsWith(staging.canonicalPath + File.separator)) {
                            "Invalid Android Dart SDK archive path"
                        }
                        if (entry.isDirectory) {
                            file.mkdirs()
                        } else {
                            file.parentFile!!.mkdirs()
                            file.outputStream().use { zip.copyTo(it) }
                        }
                        zip.closeEntry()
                        entry = zip.nextEntry
                    }
                }
                check(File(staging, "lib/core/core.dart").isFile) { "Dart SDK libraries are missing" }
                File(staging, ".qfli-sdk-id").writeText(id)
                check(!home.exists() || home.deleteRecursively()) { "Cannot replace Android Dart SDK" }
                check(staging.renameTo(home)) { "Cannot install Android Dart SDK" }
            } finally {
                staging.deleteRecursively()
            }
        }
        val libraries = manifest.getJSONArray("libraries")
        for (index in 0 until libraries.length()) {
            val item = libraries.getJSONObject(index)
            val target = File(nativeDir, item.getString("library"))
            check(target.isFile) { "Dart SDK native file is missing: ${target.name}" }
            val link = File(home, item.getString("path"))
            link.parentFile!!.mkdirs()
            try {
                Os.remove(link.path)
            } catch (error: ErrnoException) {
                if (error.errno != OsConstants.ENOENT) throw error
            }
            Os.symlink(target.path, link.path)
        }
        check(vm.canExecute()) { "Android Dart VM is not executable" }
        check(File(home, "tmp").isDirectory || File(home, "tmp").mkdirs()) { "Cannot create Dart SDK temporary directory" }
        return mapOf("home" to home.path, "vm" to vm.path, "libraryDirectory" to nativeDir)
    }
}
