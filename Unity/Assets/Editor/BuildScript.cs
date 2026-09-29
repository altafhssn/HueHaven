using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace HueHaven.Editor
{
    /// <summary>
    /// Signed Android builds, the Unity counterpart of build_apk.sh / build_release.sh.
    /// Keystore comes from KEYSTORE_PATH / KEYSTORE_USER / KEYSTORE_PASS (environment, or the
    /// repo-root .keystore.env used by the Godot scripts). Batch mode:
    ///   Unity -batchmode -quit -projectPath Unity -executeMethod HueHaven.Editor.BuildScript.BuildApk
    /// </summary>
    public static class BuildScript
    {
        [MenuItem("HueHaven/Build/Android APK (sideload)")]
        public static void BuildApk() { Build(false); }

        [MenuItem("HueHaven/Build/Android AAB (Play Store)")]
        public static void BuildAab() { Build(true); }

        static void Build(bool bundle)
        {
            var secrets = LoadSecrets();
            string ks, user, pass;
            secrets.TryGetValue("KEYSTORE_PATH", out ks);
            secrets.TryGetValue("KEYSTORE_USER", out user);
            secrets.TryGetValue("KEYSTORE_PASS", out pass);

            if (string.IsNullOrEmpty(ks) || string.IsNullOrEmpty(user) || string.IsNullOrEmpty(pass) || !File.Exists(ks))
            {
                Fail("Keystore not configured. Set KEYSTORE_PATH, KEYSTORE_USER and KEYSTORE_PASS " +
                     "(environment or ../.keystore.env), and make sure the keystore file exists.");
                return;
            }

            PlayerSettings.Android.useCustomKeystore = true;
            PlayerSettings.Android.keystoreName = Path.GetFullPath(ks);
            PlayerSettings.Android.keystorePass = pass;
            PlayerSettings.Android.keyaliasName = user;
            PlayerSettings.Android.keyaliasPass = pass;

            string ext = bundle ? "aab" : "apk";
            string outPath = "build/android/huehaven-v" + PlayerSettings.bundleVersion + "." + ext;
            Directory.CreateDirectory(Path.GetDirectoryName(outPath));

            EditorUserBuildSettings.buildAppBundle = bundle;
            var options = new BuildPlayerOptions
            {
                scenes = new[] { "Assets/Scenes/Main.unity" },
                locationPathName = outPath,
                target = BuildTarget.Android,
                options = BuildOptions.None,
            };
            var report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != UnityEditor.Build.Reporting.BuildResult.Succeeded)
            {
                Fail("Build failed: " + report.summary.result);
                return;
            }
            Debug.Log("HueHaven: built " + outPath + " (" + report.summary.totalSize / 1024 / 1024 + " MB)");
        }

        static Dictionary<string, string> LoadSecrets()
        {
            var d = new Dictionary<string, string>();
            foreach (var k in new[] { "KEYSTORE_PATH", "KEYSTORE_USER", "KEYSTORE_PASS" })
            {
                var v = Environment.GetEnvironmentVariable(k);
                if (!string.IsNullOrEmpty(v)) d[k] = v;
            }
            // Fall back to the Godot-era .keystore.env at the repo root: KEY=VALUE, optional "export ".
            string envFile = Path.GetFullPath(Path.Combine(Application.dataPath, "../../.keystore.env"));
            if (File.Exists(envFile))
            {
                foreach (var raw in File.ReadAllLines(envFile))
                {
                    var line = raw.Trim();
                    if (line.StartsWith("export ")) line = line.Substring(7).Trim();
                    int eq = line.IndexOf('=');
                    if (line.StartsWith("#") || eq <= 0) continue;
                    string key = line.Substring(0, eq).Trim();
                    string val = line.Substring(eq + 1).Trim().Trim('"', '\'');
                    if (!d.ContainsKey(key)) d[key] = val;
                }
            }
            return d;
        }

        static void Fail(string msg)
        {
            Debug.LogError("HueHaven: " + msg);
            if (Application.isBatchMode) EditorApplication.Exit(1);
        }
    }
}
