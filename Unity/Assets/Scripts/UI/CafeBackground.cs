using UnityEngine;
using UnityEngine.UI;

namespace HueHaven
{
    /// <summary>
    /// Warm cream gradient with a slow per-theme accent glow and drifting steam motes.
    /// Port of Style.draw_themed_background() / _draw_clean_bg().
    /// </summary>
    public sealed class CafeBackground : MonoBehaviour
    {
        struct Mote
        {
            public Image Glow, Core;
            public float BaseX, SeedY, Radius, Speed, Sway, Phase;
        }

        const int MoteCount = 14;

        Vector2 _vp;
        Image[] _glow;
        Mote[] _motes;
        float _glowR;

        public static CafeBackground Create(Transform parent, Vector2 viewport, Theme theme)
        {
            var rt = UIKit.Stretch("CafeBackground", parent);
            var bg = rt.gameObject.AddComponent<CafeBackground>();
            bg.Build(viewport, theme);
            return bg;
        }

        void Build(Vector2 vp, Theme theme)
        {
            _vp = vp;
            var root = (RectTransform)transform;

            // Vertical three-stop gradient: cream -> mid cream (60%) -> honey wood.
            var grad = UIKit.Node("Gradient", root, 0, 0, vp.x, vp.y).gameObject.AddComponent<VectorGraphic>();
            grad.raycastTarget = false;
            float split = vp.y * 0.6f;
            grad.FillGradientRect(0, 0, vp.x, split, Palette.BgTop, Palette.BgMid);
            grad.FillGradientRect(0, split, vp.x, vp.y - split, Palette.BgMid, Palette.BgBottom);
            grad.Commit();

            // Soft accent wash near the top.
            Color accent = Palette.ThemeGlow(theme);
            _glowR = vp.x * 0.80f;
            _glow = new[]
            {
                UIKit.Circle(root, 0, 0, _glowR, Palette.WithAlpha(accent, 0.08f), "Glow0"),
                UIKit.Circle(root, 0, 0, _glowR * 0.65f, Palette.WithAlpha(accent, 0.10f), "Glow1"),
                UIKit.Circle(root, 0, 0, _glowR * 0.35f, Palette.WithAlpha(accent, 0.12f), "Glow2"),
            };

            // Warm-brown motes floating up like cafe steam.
            var rng = new System.Random(7);
            _motes = new Mote[MoteCount];
            for (int i = 0; i < MoteCount; i++)
            {
                var m = new Mote
                {
                    BaseX = (float)rng.NextDouble() * vp.x,
                    SeedY = (float)rng.NextDouble() * vp.y,
                    Radius = Mathf.Lerp(1.2f, 2.6f, (float)rng.NextDouble()),
                    Speed = Mathf.Lerp(6f, 14f, (float)rng.NextDouble()),
                    Sway = Mathf.Lerp(10f, 22f, (float)rng.NextDouble()),
                    Phase = (float)rng.NextDouble() * Mathf.PI * 2f,
                };
                m.Glow = UIKit.Circle(root, 0, 0, m.Radius * 1.6f, Color.white, "MoteGlow");
                m.Core = UIKit.Circle(root, 0, 0, m.Radius, Color.white, "MoteCore");
                _motes[i] = m;
            }
            Tick(0f);
        }

        void Update() { Tick(Time.unscaledTime); }

        void Tick(float t)
        {
            float gx = _vp.x * (0.5f + 0.08f * Mathf.Sin(t * 0.05f));
            float gy = _vp.y * 0.18f;
            float[] radii = { _glowR, _glowR * 0.65f, _glowR * 0.35f };
            for (int i = 0; i < _glow.Length; i++)
                UIKit.Place(_glow[i].rectTransform, gx - radii[i], gy - radii[i], radii[i] * 2f, radii[i] * 2f);

            for (int i = 0; i < _motes.Length; i++)
            {
                var m = _motes[i];
                float y = Mod(m.SeedY - t * m.Speed, _vp.y + 30f) - 15f;
                float x = m.BaseX + Mathf.Sin(t * 0.3f + m.Phase) * m.Sway;
                float a = 0.20f + 0.12f * Mathf.Sin(t * 0.4f + m.Phase);
                UIKit.Place(m.Glow.rectTransform, x - m.Radius * 1.6f, y - m.Radius * 1.6f, m.Radius * 3.2f, m.Radius * 3.2f);
                UIKit.Place(m.Core.rectTransform, x - m.Radius, y - m.Radius, m.Radius * 2f, m.Radius * 2f);
                m.Glow.color = new Color(0.55f, 0.40f, 0.25f, a * 0.18f);
                m.Core.color = new Color(0.85f, 0.65f, 0.45f, a * 0.60f);
            }
        }

        static float Mod(float v, float m) { return v - m * Mathf.Floor(v / m); }
    }
}
