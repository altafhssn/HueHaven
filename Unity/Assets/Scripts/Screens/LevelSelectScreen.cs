using UnityEngine;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>Scrollable grid of level tiles for one pack. Port of LevelSelect.gd.</summary>
    public static class LevelSelectScreen
    {
        const int Cols = 4;
        const float Cell = 88f, Gap = 14f, GridTop = 180f, BottomPad = 24f;

        public static GameObject Build(GameController g, Transform parent, int packIndex)
        {
            Vector2 vp = g.Viewport;
            var packs = LevelGenerator.Packs;
            if (packIndex < 0 || packIndex >= packs.Length) packIndex = 0;
            var pack = packs[packIndex];
            int startLevel = LevelGenerator.PackStartLevel(packIndex);

            var root = UIKit.Stretch("LevelSelect", parent);
            CafeBackground.Create(root, vp, Palette.ThemeForPack(packIndex));

            UIKit.IconButton(root, "back", 16, 16, 44, g.ShowPackSelect);
            UIKit.Label(root, pack.Name, 28, Palette.Text, 0, 22, vp.x, 36);
            UIKit.Label(root, pack.Tagline, 12, Palette.TextMuted, 0, 62, vp.x, 16);

            int completed = 0;
            for (int i = 0; i < pack.Levels; i++)
                if (g.Progress.GetStars(startLevel + i) > 0) completed++;
            UIKit.Label(root, completed + " / " + pack.Levels + " complete", 12, Palette.TextMuted, 0, 92, vp.x, 16);

            // Slim progress bar.
            float barW = vp.x - 120f;
            UIKit.Round(root, 60, 116, barW, 4, Palette.WithAlpha(Palette.Panel, 0.7f), 2f, "ProgressTrack");
            float fill = barW * Mathf.Clamp01((float)completed / pack.Levels);
            if (fill > 1f) UIKit.Round(root, 60, 116, fill, 4, Palette.Accent, 2f, "ProgressFill");

            BuildGrid(g, root, vp, pack, startLevel);
            return root.gameObject;
        }

        static void BuildGrid(GameController g, Transform root, Vector2 vp, PackDef pack, int startLevel)
        {
            float viewH = vp.y - GridTop - BottomPad;

            // ScrollRect > Viewport (masked) > Content
            var scrollRt = UIKit.Node("Scroll", root, 0, GridTop, vp.x, viewH);
            var hit = scrollRt.gameObject.AddComponent<Image>();
            hit.color = new Color(0, 0, 0, 0); // lets empty space between tiles start a drag
            var scroll = scrollRt.gameObject.AddComponent<ScrollRect>();

            var viewport = UIKit.Stretch("Viewport", scrollRt);
            viewport.gameObject.AddComponent<RectMask2D>();

            int rows = Mathf.CeilToInt((float)pack.Levels / Cols);
            float contentH = 16f + rows * Cell + (rows - 1) * Gap;
            var content = UIKit.Node("Content", viewport, 0, 0, vp.x, Mathf.Max(contentH, viewH));

            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Elastic;
            scroll.scrollSensitivity = 30f;

            float gridW = Cols * Cell + (Cols - 1) * Gap;
            float offX = (vp.x - gridW) / 2f;
            int highest = g.Progress.HighestUnlocked;

            for (int i = 0; i < pack.Levels; i++)
            {
                int levelIdx = startLevel + i;
                float x = offX + (i % Cols) * (Cell + Gap);
                float y = 8f + (i / Cols) * (Cell + Gap);
                BuildTile(g, content, levelIdx, x, y, levelIdx <= highest, levelIdx == highest, g.Progress.GetStars(levelIdx));
            }

            // Bring the level the player is up to into view.
            if (highest >= startLevel && highest < startLevel + pack.Levels)
            {
                float rowY = 8f + ((highest - startLevel) / Cols) * (Cell + Gap);
                float maxScroll = Mathf.Max(0f, content.sizeDelta.y - viewH);
                content.anchoredPosition = new Vector2(0f, Mathf.Clamp(rowY - viewH * 0.4f, 0f, maxScroll));
            }
        }

        static void BuildTile(GameController g, Transform parent, int levelIdx, float x, float y, bool unlocked, bool current, int stars)
        {
            Color bg, border, text;
            if (current)
            {
                bg = Palette.Accent; border = Palette.AccentDim; text = Palette.TextOnAccent;
            }
            else if (unlocked)
            {
                if (stars > 0) { bg = Palette.PanelHi; border = Palette.PanelBorderHi; }
                else { bg = Palette.Panel; border = Palette.PanelBorder; }
                text = Palette.Text;
            }
            else
            {
                bg = new Color(Palette.Panel.r * 0.6f, Palette.Panel.g * 0.6f, Palette.Panel.b * 0.6f, 1f);
                border = new Color(Palette.PanelBorder.r * 0.6f, Palette.PanelBorder.g * 0.6f, Palette.PanelBorder.b * 0.6f, 1f);
                text = Palette.TextDim;
            }

            var theme = ButtonTheme.FromBase(bg, border, text, text);
            int captured = levelIdx;
            var btn = UIKit.Button(parent, x, y, Cell, Cell, theme, 14f, unlocked ? (levelIdx + 1).ToString() : "", 22,
                () => g.StartLevel(captured));
            btn.name = "Level_" + (levelIdx + 1);
            btn.Interactable = unlocked;

            if (!unlocked)
            {
                UIKit.Icon(btn.transform, "lock", (Cell - Cell * 0.55f) / 2f, (Cell - Cell * 0.55f) / 2f, Cell * 0.55f, Palette.TextDim);
                return;
            }
            if (stars > 0)
            {
                const float starSize = 18f, gap = 4f;
                float total = stars * starSize + (stars - 1) * gap;
                float sx0 = (Cell - total) / 2f;
                for (int s = 0; s < stars; s++)
                    UIKit.Icon(btn.transform, "star", sx0 + s * (starSize + gap), Cell - 22f, starSize, Palette.Star);
            }
        }
    }
}
