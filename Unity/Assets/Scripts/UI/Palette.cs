using UnityEngine;

namespace HueHaven
{
    public enum Theme { Underwater = 0, Alchemy = 1, SciFi = 2, Forest = 3 }

    /// <summary>Warm cafe palette — colours lifted 1:1 from scripts/Style.gd.</summary>
    public static class Palette
    {
        public static Color Hex(string hex)
        {
            Color c;
            return ColorUtility.TryParseHtmlString(hex, out c) ? c : Color.magenta;
        }

        public static Color WithAlpha(Color c, float a) { c.a = a; return c; }

        /// <summary>Godot Color.lightened — lerp toward white, alpha kept.</summary>
        public static Color Lightened(Color c, float amt)
        {
            float a = c.a;
            var r = Color.Lerp(c, Color.white, amt);
            r.a = a;
            return r;
        }

        /// <summary>Godot Color.darkened — lerp toward black, alpha kept.</summary>
        public static Color Darkened(Color c, float amt)
        {
            float a = c.a;
            var r = Color.Lerp(c, Color.black, amt);
            r.a = a;
            return r;
        }

        // Panels & cards (cafe cream + wood tones)
        public static readonly Color Panel = Hex("#F5EBDA");
        public static readonly Color PanelHi = Hex("#FAF1E0");
        public static readonly Color PanelBorder = Hex("#8A6E4F");
        public static readonly Color PanelBorderHi = Hex("#A98870");

        // Accent (boba peach for primary actions)
        public static readonly Color Accent = Hex("#E89B7A");
        public static readonly Color AccentHi = Hex("#F0B095");
        public static readonly Color AccentDim = Hex("#C77A5C");

        // Text (warm dark brown on cream)
        public static readonly Color Text = Hex("#3D2A1A");
        public static readonly Color TextMuted = Hex("#7A5F46");
        public static readonly Color TextDim = Hex("#B59B82");
        public static readonly Color TextOnAccent = Hex("#1A1208");

        // Semantic
        public static readonly Color Star = Hex("#E5A640");
        public static readonly Color Danger = Hex("#C5604D");
        public static readonly Color Success = Hex("#7DA66A");

        // Buttons
        public static readonly Color BtnBg = Hex("#F5EBDA");
        public static readonly Color BtnBgHover = Hex("#FAF1E0");
        public static readonly Color BtnBgPressed = Hex("#E5D7BD");
        public static readonly Color BtnBorder = Hex("#8A6E4F");
        public static readonly Color BtnDisabledBg = Hex("#1A1612");
        public static readonly Color BtnDisabledBorder = Hex("#252019");

        // Background gradient
        public static readonly Color BgTop = Hex("#F5EBDA");
        public static readonly Color BgMid = Hex("#EDDCC0");
        public static readonly Color BgBottom = Hex("#D8BFA2");

        public static readonly Color[] ConfettiColors =
        {
            Hex("#EF5350"), Hex("#42A5F5"), Hex("#66BB6A"),
            Hex("#FFEE58"), Hex("#AB47BC"), Hex("#FFA726"),
        };

        // Fallback tints, used only if a pearl texture is missing.
        public static readonly Color[] FallbackBall =
        {
            Hex("#C84A50"), Hex("#4080B5"), Hex("#4FA868"), Hex("#D8B440"),
            Hex("#8A66B0"), Hex("#D88A40"), Hex("#3E9AA8"), Hex("#C4688E"),
            Hex("#90B055"), Hex("#3F8E88"), Hex("#5868A8"), Hex("#856047"),
        };

        /// <summary>Six packs cycle through four accent themes.</summary>
        public static Theme ThemeForPack(int packIdx)
        {
            Theme[] cycle = { Theme.Underwater, Theme.Alchemy, Theme.Forest, Theme.SciFi, Theme.Alchemy, Theme.Forest };
            return cycle[packIdx % cycle.Length];
        }

        /// <summary>Per-theme soft accent wash used on the background.</summary>
        public static Color ThemeGlow(Theme t)
        {
            switch (t)
            {
                case Theme.Alchemy: return Hex("#E5A640"); // caramel gold
                case Theme.SciFi: return Hex("#9E7CB8");   // taro lavender
                case Theme.Forest: return Hex("#7DA66A");  // matcha green
                default: return Hex("#E89B7A");            // boba peach
            }
        }

        /// <summary>Pack tile colours: (background tint, accent).</summary>
        public static void PackTile(Theme t, out Color bg, out Color accent)
        {
            switch (t)
            {
                case Theme.Alchemy: bg = Hex("#F4E0C0"); accent = Hex("#C68845"); break; // brown sugar
                case Theme.SciFi: bg = Hex("#E8DCEA"); accent = Hex("#9E7CB8"); break;   // taro
                case Theme.Forest: bg = Hex("#DCEAD0"); accent = Hex("#7DA66A"); break;  // matcha
                default: bg = Hex("#F5E4D2"); accent = Hex("#E89B7A"); break;            // milk tea
            }
        }
    }
}
