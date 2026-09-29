using System.Collections.Generic;
using UnityEngine;

namespace HueHaven
{
    /// <summary>
    /// Loads the boba-theme textures from Resources/Art. Port of scripts/Assets.gd; the
    /// 12 colour slots map onto the 8 flavours exactly as in the Godot version.
    /// </summary>
    public static class GameAssets
    {
        static readonly string[] PearlMap =
        {
            "strawberry", // 0 red
            "blueberry",  // 1 blue
            "matcha",     // 2 green
            "brownsugar", // 3 yellow
            "taro",       // 4 purple
            "mango",      // 5 orange
            "peach",      // 6 cyan
            "strawberry", // 7 pink (reuse)
            "matcha",     // 8 lime (reuse)
            "peach",      // 9 teal (reuse)
            "blueberry",  // 10 indigo (reuse)
            "milktea",    // 11 brown
        };

        static readonly string[] StrawNames = { "mint", "peach", "lavender", "blue", "yellow", "pink" };

        static readonly Dictionary<string, Texture2D> Cache = new Dictionary<string, Texture2D>();

        static Texture2D Load(string path)
        {
            Texture2D t;
            if (Cache.TryGetValue(path, out t)) return t;
            t = Resources.Load<Texture2D>(path);
            if (t == null) Debug.LogWarning("HueHaven: missing texture Resources/" + path);
            Cache[path] = t;
            return t;
        }

        /// <summary>Pearl texture for a colour index (null if the art is missing).</summary>
        public static Texture2D Pearl(int colorIdx)
        {
            if (colorIdx < 0 || colorIdx >= PearlMap.Length) colorIdx = 0;
            return Load("Art/pearls/" + PearlMap[colorIdx]);
        }

        public static Texture2D Special(BallKind kind)
        {
            switch (kind)
            {
                case BallKind.Bomb: return Load("Art/pearls_special/popping");
                case BallKind.Rainbow: return Load("Art/pearls_special/rainbow");
                case BallKind.Magnet: return Load("Art/pearls_special/sticky");
                case BallKind.Stone: return Load("Art/pearls_special/frozen");
                case BallKind.Hourglass: return Load("Art/pearls_special/sand");
                default: return null;
            }
        }

        public static Texture2D CafeBackground { get { return Load("Art/bg/cafe"); } }
        public static Texture2D Logo { get { return Load("Art/icon"); } }

        /// <summary>Straws cycle by pack index.</summary>
        public static Texture2D Straw(int packIdx)
        {
            return Load("Art/straws/" + StrawNames[packIdx % StrawNames.Length]);
        }
    }
}
