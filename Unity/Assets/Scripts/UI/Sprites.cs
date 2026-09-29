using System.Collections.Generic;
using UnityEngine;

namespace HueHaven
{
    /// <summary>
    /// Procedurally generated anti-aliased UI sprites (circle, 9-slice rounded rect,
    /// 9-slice rounded outline). Nothing to author or import — the game's look stays
    /// fully in code, like the Godot version's StyleBoxFlat / draw_circle calls.
    /// </summary>
    public static class Sprites
    {
        /// <summary>
        /// Sliced sprites are baked at this many texels per canvas unit and displayed with
        /// Image.pixelsPerUnitMultiplier = Scale, so corners stay crisp on high-DPI screens.
        /// </summary>
        public const int Scale = 4;

        static Sprite _circle;
        static readonly Dictionary<int, Sprite> Rounded = new Dictionary<int, Sprite>();
        static readonly Dictionary<long, Sprite> Rings = new Dictionary<long, Sprite>();

        public static Sprite Circle
        {
            get
            {
                if (_circle != null) return _circle;
                const int n = 256;
                var tex = NewTexture(n, n);
                var px = new Color32[n * n];
                float half = n * 0.5f;
                for (int y = 0; y < n; y++)
                    for (int x = 0; x < n; x++)
                    {
                        float dx = x + 0.5f - half, dy = y + 0.5f - half;
                        float d = Mathf.Sqrt(dx * dx + dy * dy) - half;
                        px[y * n + x] = White(Mathf.Clamp01(0.5f - d));
                    }
                tex.SetPixels32(px);
                tex.Apply(false, true);
                _circle = Sprite.Create(tex, new Rect(0, 0, n, n), new Vector2(0.5f, 0.5f), 100f);
                _circle.name = "hh_circle";
                return _circle;
            }
        }

        /// <summary>Filled rounded rect for use with Image.type = Sliced.</summary>
        public static Sprite RoundedRect(float radius)
        {
            int rt = Mathf.Max(1, Mathf.RoundToInt(radius * Scale));
            Sprite s;
            if (Rounded.TryGetValue(rt, out s) && s != null) return s;
            s = BakeRounded(rt, 0);
            Rounded[rt] = s;
            return s;
        }

        /// <summary>Rounded outline (transparent centre) for Image.type = Sliced.</summary>
        public static Sprite RoundedRing(float radius, float stroke)
        {
            int rt = Mathf.Max(1, Mathf.RoundToInt(radius * Scale));
            int st = Mathf.Max(1, Mathf.RoundToInt(stroke * Scale));
            long key = ((long)rt << 20) | (long)st;
            Sprite s;
            if (Rings.TryGetValue(key, out s) && s != null) return s;
            s = BakeRounded(rt, st);
            Rings[key] = s;
            return s;
        }

        static Sprite BakeRounded(int rt, int stroke)
        {
            int size = 2 * rt + 2; // 2-texel stretchable centre
            var tex = NewTexture(size, size);
            var px = new Color32[size * size];
            float half = size * 0.5f;
            float inner = half - rt;
            for (int y = 0; y < size; y++)
                for (int x = 0; x < size; x++)
                {
                    float qx = Mathf.Abs(x + 0.5f - half) - inner;
                    float qy = Mathf.Abs(y + 0.5f - half) - inner;
                    float ox = Mathf.Max(qx, 0f), oy = Mathf.Max(qy, 0f);
                    float sdf = Mathf.Sqrt(ox * ox + oy * oy) + Mathf.Min(Mathf.Max(qx, qy), 0f) - rt;
                    float a;
                    if (stroke <= 0) a = Mathf.Clamp01(0.5f - sdf);
                    else
                    {
                        float d = Mathf.Abs(sdf + stroke * 0.5f) - stroke * 0.5f;
                        a = Mathf.Clamp01(0.5f - d);
                    }
                    px[y * size + x] = White(a);
                }
            tex.SetPixels32(px);
            tex.Apply(false, true);
            var sprite = Sprite.Create(tex, new Rect(0, 0, size, size), new Vector2(0.5f, 0.5f), 100f,
                0, SpriteMeshType.FullRect, new Vector4(rt, rt, rt, rt));
            sprite.name = stroke > 0 ? "hh_ring_" + rt + "_" + stroke : "hh_round_" + rt;
            return sprite;
        }

        static Texture2D NewTexture(int w, int h)
        {
            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false);
            tex.wrapMode = TextureWrapMode.Clamp;
            tex.filterMode = FilterMode.Bilinear;
            tex.hideFlags = HideFlags.HideAndDontSave;
            return tex;
        }

        static Color32 White(float a) { return new Color32(255, 255, 255, (byte)Mathf.RoundToInt(a * 255f)); }
    }
}
