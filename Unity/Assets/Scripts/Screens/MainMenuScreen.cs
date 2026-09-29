using UnityEngine;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>Title screen — logo, wordmark, Play / Settings, progress line. Port of MainMenu.gd.</summary>
    public static class MainMenuScreen
    {
        public static GameObject Build(GameController g, Transform parent)
        {
            Vector2 vp = g.Viewport;
            var root = UIKit.Stretch("MainMenu", parent);
            CafeBackground.Create(root, vp, Theme.Underwater);

            BuildLogo(root, vp);
            BuildTitle(root, vp);

            UIKit.Label(root, "A serene sorting puzzle", 14, Palette.TextMuted,
                0, UIKit.TopForBaseline(vp.y * 0.48f, 14), vp.x, 20);

            var play = UIKit.IconTextButton(root, "play", "Play", (vp.x - 240f) / 2f, vp.y * 0.58f, 240, 60,
                ButtonTheme.Primary(), 19, 23, 10f, g.ShowPackSelect);
            play.name = "PlayButton";

            var settings = UIKit.IconTextButton(root, "settings", "Settings", (vp.x - 180f) / 2f, vp.y * 0.58f + 76f, 180, 48,
                ButtonTheme.Secondary(), 16, 20, 10f, g.ShowSettings);
            settings.name = "SettingsButton";

            int totalStars = 0;
            int unlocked = g.Progress.HighestUnlocked;
            for (int i = 0; i <= unlocked; i++) totalStars += g.Progress.GetStars(i);
            UIKit.Label(root, totalStars + " stars   ·   Level " + (unlocked + 1) + " of " + LevelGenerator.TotalLevels,
                14, Palette.TextMuted, 0, vp.y * 0.58f + 142f, vp.x, 22);

            return root.gameObject;
        }

        // Logo mark: assets/icon.png with a soft warm drop shadow, so it always matches the app icon.
        static void BuildLogo(Transform root, Vector2 vp)
        {
            float cx = vp.x * 0.5f, cy = vp.y * 0.22f, size = 180f;
            float x0 = cx - size * 0.5f, y0 = cy - size * 0.5f;
            for (int k = 0; k < 3; k++)
                UIKit.Round(root, x0, y0 + (k + 1) * 2f, size, size, new Color(0.20f, 0.13f, 0.08f, 0.10f), size * 0.22f, "LogoShadow");

            var tex = GameAssets.Logo;
            if (tex == null)
            {
                UIKit.Round(root, x0, y0, size, size, Palette.Accent, size * 0.22f, "LogoFallback");
                return;
            }
            var rt = UIKit.Node("Logo", root, x0, y0, size, size);
            var raw = rt.gameObject.AddComponent<RawImage>();
            raw.texture = tex;
            raw.raycastTarget = false;
        }

        // Two-tone wordmark: "Hue" in espresso, "Haven" in peach, each with a soft glow.
        static void BuildTitle(Transform root, Vector2 vp)
        {
            const int size = 46;
            float top = UIKit.TopForBaseline(vp.y * 0.42f, size);
            var hue = UIKit.Label(root, "Hue", size, Palette.Text, 0, top, 200, 60, TextAnchor.UpperLeft, "TitleHue");
            var haven = UIKit.Label(root, "Haven", size, Palette.Accent, 0, top, 240, 60, TextAnchor.UpperLeft, "TitleHaven");
            float hueW = UIKit.TextWidth(hue), havenW = UIKit.TextWidth(haven);
            float x0 = vp.x * 0.5f - (hueW + havenW) * 0.5f;
            hue.rectTransform.anchoredPosition = new Vector2(x0, -top);
            haven.rectTransform.anchoredPosition = new Vector2(x0 + hueW, -top);
            foreach (var t in new[] { hue, haven })
            {
                var glow = t.gameObject.AddComponent<Outline>();
                glow.effectColor = new Color(Palette.Accent.r, Palette.Accent.g, Palette.Accent.b, 0.25f);
                glow.effectDistance = new Vector2(3f, 3f);
            }
        }
    }
}
