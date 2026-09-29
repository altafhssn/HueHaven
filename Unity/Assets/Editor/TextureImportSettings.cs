using UnityEditor;

namespace HueHaven.Editor
{
    /// <summary>
    /// Import settings for the game art under Resources/Art. Godot fixes transparent-edge
    /// colour fringing on import by default; Unity needs "Alpha Is Transparency" for the same.
    /// </summary>
    sealed class TextureImportSettings : AssetPostprocessor
    {
        void OnPreprocessTexture()
        {
            if (!assetPath.StartsWith("Assets/Resources/Art/") && !assetPath.StartsWith("Assets/Icons/")) return;
            var importer = (TextureImporter)assetImporter;
            importer.textureType = TextureImporterType.Default;
            importer.alphaSource = TextureImporterAlphaSource.FromInput;
            importer.alphaIsTransparency = true;
            importer.npotScale = TextureImporterNPOTScale.None;
            importer.wrapMode = UnityEngine.TextureWrapMode.Clamp;
            importer.filterMode = UnityEngine.FilterMode.Bilinear;

            // The full-screen backdrop is drawn 1:1 — keep its resolution and skip mip memory.
            bool backdrop = assetPath.Contains("/bg/");
            importer.mipmapEnabled = !backdrop;
            importer.maxTextureSize = backdrop ? 4096 : 2048;
        }
    }
}
