using UnityEngine;

namespace HueHaven
{
    /// <summary>Full-screen settings page. Port of SettingsScreen.gd.</summary>
    public static class SettingsScreen
    {
        /// <summary>Settings row: label on the left, ON/OFF on the right.</summary>
        public static StyledButton MakeRow(Transform parent, string label, float x, float y, float w, float h, System.Action onClick,
            out UnityEngine.UI.Text state)
        {
            var b = UIKit.Button(parent, x, y, w, h, ButtonTheme.Secondary(), 24f, label, 14, onClick,
                TextAnchor.MiddleLeft, 20f);
            state = UIKit.Label(b.transform, "", 14, Palette.Text, 0, 0, w - 20f, h, TextAnchor.MiddleRight, "State");
            return b;
        }

        public static void SetState(UnityEngine.UI.Text t, bool on)
        {
            t.text = on ? "ON" : "OFF";
            t.color = on ? Palette.Text : Palette.TextMuted;
        }

        public static GameObject Build(GameController g, Transform parent)
        {
            Vector2 vp = g.Viewport;
            var root = UIKit.Stretch("Settings", parent);
            CafeBackground.Create(root, vp, Theme.Underwater);

            UIKit.IconButton(root, "back", 16, 16, 44, g.ShowMainMenu);
            UIKit.Label(root, "Settings", 28, Palette.Accent, 0, 40, vp.x, 40);

            float top = vp.y * 0.20f;
            UIKit.Label(root, "GAME", 11, Palette.TextDim, 24, top, vp.x - 48, 18, TextAnchor.UpperLeft);

            UnityEngine.UI.Text cbState = null, soundState = null, hapticState = null;
            System.Action refresh = () =>
            {
                SetState(cbState, g.Colorblind);
                SetState(soundState, !g.Muted);
                SetState(hapticState, g.HapticsEnabled);
            };

            float w = vp.x - 48f;
            MakeRow(root, "Colorblind shapes", 24, top + 24, w, 48, () => { g.ToggleColorblind(); refresh(); }, out cbState);
            MakeRow(root, "Sound", 24, top + 84, w, 48, () => { g.ToggleMute(); refresh(); }, out soundState);
            MakeRow(root, "Haptics", 24, top + 144, w, 48, () => { g.ToggleHaptics(); refresh(); }, out hapticState);

            UIKit.Label(root, "DATA", 11, Palette.TextDim, 24, top + 230, vp.x - 48, 18, TextAnchor.UpperLeft);

            var reset = UIKit.Button(root, 24, top + 254, w, 48, ButtonTheme.Secondary(), 24f, "Reset progress", 14,
                () => { g.Progress.ResetAll(); refresh(); });
            reset.Theme.Normal.Text = Palette.Danger;
            reset.Theme.Hover.Text = Palette.Danger;
            reset.Theme.Pressed.Text = Palette.Danger;
            reset.Refresh();

            UIKit.Label(root, "v" + Application.version + " — HueHaven", 11, Palette.TextDim, 0, vp.y - 30, vp.x, 20);

            refresh();
            return root.gameObject;
        }
    }
}
