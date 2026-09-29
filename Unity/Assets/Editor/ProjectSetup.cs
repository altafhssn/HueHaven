using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace HueHaven.Editor
{
    /// <summary>
    /// One-time project configuration on first open: identity, portrait, Android targets, colour space,
    /// and a Main scene in the build. Re-run any time from the HueHaven menu.
    /// The game itself needs no scene setup — see Bootstrap in Scripts/GameController.cs.
    /// </summary>
    [InitializeOnLoad]
    static class ProjectSetup
    {
        const string DoneKey = "HueHaven.ProjectSetup.v1";
        const string ScenePath = "Assets/Scenes/Main.unity";

        static ProjectSetup()
        {
            EditorApplication.delayCall += () =>
            {
                if (EditorPrefs.GetBool(DoneKey + Application.dataPath, false)) return;
                Apply();
                EditorPrefs.SetBool(DoneKey + Application.dataPath, true);
            };
        }

        [MenuItem("HueHaven/Apply Project Settings")]
        public static void Apply()
        {
            PlayerSettings.companyName = "altafhssn";
            PlayerSettings.productName = "HueHaven";
            PlayerSettings.bundleVersion = "1.0.0";

            // Gamma: the UI palette is authored in sRGB values (matches the Godot look).
            PlayerSettings.colorSpace = ColorSpace.Gamma;

            // Portrait only.
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
            PlayerSettings.allowedAutorotateToPortrait = true;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = false;
            PlayerSettings.allowedAutorotateToLandscapeRight = false;

            // Android — same package id / version as the Godot export preset.
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, "com.altafhssn.huehaven");
            PlayerSettings.Android.bundleVersionCode = 1;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel23;
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARMv7 | AndroidArchitecture.ARM64;

            EnsureMainScene();

#if !ENABLE_LEGACY_INPUT_MANAGER
            Debug.LogWarning("HueHaven: Active Input Handling is 'Input System (New)' only. Set it to 'Both' or " +
                             "'Input Manager (Old)' in Project Settings > Player so tapping works out of the box.");
#endif
            AssetDatabase.SaveAssets();
            Debug.Log("HueHaven: project settings applied.");
        }

        static void EnsureMainScene()
        {
            if (!File.Exists(ScenePath))
            {
                var open = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
                // Only replace an empty, untitled scene — never clobber someone's work.
                if (open.isDirty || !string.IsNullOrEmpty(open.path)) return;
                Directory.CreateDirectory("Assets/Scenes");
                var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                EditorSceneManager.SaveScene(scene, ScenePath);
            }
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        }
    }
}
