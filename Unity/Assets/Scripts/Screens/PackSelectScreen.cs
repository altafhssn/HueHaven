using UnityEngine;

namespace HueHaven
{
    /// <summary>2x3 grid of chapter tiles, locked behind star thresholds. Port of PackSelect.gd.</summary>
    public static class PackSelectScreen
    {
        const int Cols = 2;
        const float CellW = 210f, CellH = 180f, CellGap = 16f, GridTop = 150f;

        public static GameObject Build(GameController g, Transform parent)
        {
            Vector2 vp = g.Viewport;
            var root = UIKit.Stretch("PackSelect", parent);
            CafeBackground.Create(root, vp, Theme.Underwater);

            UIKit.IconButton(root, "back", 16, 16, 44, g.ShowMainMenu);
            UIKit.Label(root, "CHAPTERS", 12, Palette.TextDim, 0, 28, vp.x, 16);
            UIKit.Label(root, "Choose Your Path", 22, Palette.Text, 0, 48, vp.x, 30);

            BuildTotalStars(root, vp, g.Progress.TotalStars());

            float gridW = Cols * CellW + (Cols - 1) * CellGap;
            float offX = (vp.x - gridW) / 2f;
            int startLevel = 0;
            for (int i = 0; i < LevelGenerator.Packs.Length; i++)
            {
                var pack = LevelGenerator.Packs[i];
                int col = i % Cols, row = i / Cols;
                float x = offX + col * (CellW + CellGap);
                float y = GridTop + row * (CellH + CellGap);
                BuildTile(g, root, i, pack, startLevel, x, y);
                startLevel += pack.Levels;
            }
            return root.gameObject;
        }

        // Star icon + "N stars earned", centred as one group.
        static void BuildTotalStars(Transform root, Vector2 vp, int stars)
        {
            var label = UIKit.Label(root, stars + " stars earned", 14, Palette.Text, 0, 86, 200, 26, TextAnchor.MiddleLeft);
            float textW = UIKit.TextWidth(label);
            float totalW = 22f + 6f + textW;
            float x0 = (vp.x - totalW) * 0.5f;
            UIKit.Icon(root, "star", x0, 86f + (26f - 22f) * 0.5f, 22f, Palette.Star);
            label.rectTransform.anchoredPosition = new Vector2(x0 + 28f, -86f);
            label.rectTransform.sizeDelta = new Vector2(textW + 4f, 26f);
        }

        static void BuildTile(GameController g, Transform parent, int packIdx, PackDef pack, int startLevel, float x, float y)
        {
            bool unlocked = g.Progress.TotalStars() >= pack.UnlockStars;
            int packStars = g.Progress.PackStars(startLevel, pack.Levels);
            int maxStars = pack.Levels * 3;

            Color bg, accent;
            Palette.PackTile(Palette.ThemeForPack(packIdx), out bg, out accent);

            ButtonTheme theme;
            if (unlocked)
            {
                theme = new ButtonTheme
                {
                    Normal = new Skin(bg, accent, Palette.Text),
                    Hover = new Skin(Palette.Lightened(bg, 0.06f), Palette.Lightened(accent, 0.10f), Palette.Text),
                    Pressed = new Skin(Palette.Darkened(bg, 0.08f), accent, Palette.Text),
                    Disabled = new Skin(bg, accent, Palette.Text),
                };
            }
            else
            {
                var lockedFill = Palette.Hex("#E0D4C0");
                var lockedBorder = Palette.Hex("#B59B82");
                var s = new Skin(lockedFill, lockedBorder, Palette.TextMuted);
                theme = new ButtonTheme { Normal = s, Hover = s, Pressed = s, Disabled = s };
            }

            int captured = packIdx;
            var btn = UIKit.Button(parent, x, y, CellW, CellH, theme, 18f, "", 14,
                () => g.ShowLevelSelectForPack(captured), TextAnchor.MiddleCenter, 0f, 6f, 0.35f, 2f);
            btn.name = "Pack_" + pack.Name;
            btn.Interactable = unlocked;
            // Disabled skin equals the normal one, so re-apply the intended look.
            btn.Theme = theme;
            btn.Refresh();

            float w = CellW, h = CellH;
            var content = btn.transform;

            if (unlocked)
            {
                // Soft accent glow at the top gives each tile its own colour identity.
                UIKit.Circle(content, w * 0.5f, h * 0.25f, w * 0.55f, Palette.WithAlpha(accent, 0.12f), "Glow");
                UIKit.Label(content, (packIdx + 1).ToString(), 64, Palette.WithAlpha(accent, 0.40f),
                    0, UIKit.TopForBaseline(h * 0.45f, 64), w, 80, TextAnchor.UpperCenter, "Ordinal");
                UIKit.Label(content, pack.Name, 22, Palette.Text,
                    0, UIKit.TopForBaseline(h * 0.62f, 22), w, 30, TextAnchor.UpperCenter, "Name");
                UIKit.Label(content, pack.Tagline, 11, Palette.TextMuted,
                    0, UIKit.TopForBaseline(h * 0.62f + 18f, 11), w, 16, TextAnchor.UpperCenter, "Tagline");

                // Star badge, bottom-right.
                const float badgeW = 80f, badgeH = 30f;
                float bx = w - badgeW - 10f, by = h - badgeH - 10f;
                UIKit.Round(content, bx, by, badgeW, badgeH, new Color(0, 0, 0, 0.45f), badgeH * 0.5f, "Badge");
                UIKit.Icon(content, "star", bx + 17f - 12f, by + badgeH * 0.5f - 12f, 24f, Palette.Star);
                UIKit.Label(content, packStars + "/" + maxStars, 13, Palette.Text,
                    bx + 32f, UIKit.TopForBaseline(by + badgeH * 0.5f + 5f, 13), 48, 18, TextAnchor.UpperLeft, "Count");
            }
            else
            {
                UIKit.Icon(content, "lock", w * 0.5f - 24f, h * 0.42f - 24f, 48f, Palette.TextMuted);
                UIKit.Label(content, "Earn " + pack.UnlockStars + " stars", 12, Palette.TextMuted,
                    0, UIKit.TopForBaseline(h * 0.70f, 12), w, 18, TextAnchor.UpperCenter, "Requirement");
                UIKit.Label(content, pack.Name, 16, Palette.TextDim,
                    0, UIKit.TopForBaseline(h * 0.85f, 16), w, 22, TextAnchor.UpperCenter, "Name");
            }
        }
    }
}
