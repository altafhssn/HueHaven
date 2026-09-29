namespace HueHaven
{
    public enum BallKind { Normal, Bomb, Rainbow, Stone, Magnet, Hourglass }

    /// <summary>
    /// One pearl. Regular pearls only use <see cref="Color"/> (an index into the palette);
    /// specials carry a <see cref="Kind"/>. For bombs <see cref="Meta"/> is the moves left.
    /// </summary>
    public sealed class Ball
    {
        public BallKind Kind;
        public int Color;
        public int Meta;

        public Ball(int color) { Kind = BallKind.Normal; Color = color; }
        public Ball(BallKind kind, int color, int meta = 0) { Kind = kind; Color = color; Meta = meta; }

        public bool IsSpecial => Kind != BallKind.Normal;
        public bool IsStone => Kind == BallKind.Stone;
        public bool IsRainbow => Kind == BallKind.Rainbow;

        public Ball Clone() => new Ball(Kind, Color, Meta);

        public static string KindName(BallKind k)
        {
            switch (k)
            {
                case BallKind.Bomb: return "bomb";
                case BallKind.Rainbow: return "rainbow";
                case BallKind.Stone: return "stone";
                case BallKind.Magnet: return "magnet";
                case BallKind.Hourglass: return "hourglass";
                default: return "";
            }
        }
    }
}
