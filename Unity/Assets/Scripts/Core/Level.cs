using System.Collections.Generic;

namespace HueHaven
{
    public sealed class Level
    {
        public int Colors;
        public int Capacity;
        public List<List<Ball>> Contents = new List<List<Ball>>();
        public int ParMoves;
        public List<string> Specials = new List<string>();

        public Level Clone()
        {
            var l = new Level { Colors = Colors, Capacity = Capacity, ParMoves = ParMoves };
            foreach (var t in Contents)
            {
                var tube = new List<Ball>(t.Count);
                foreach (var b in t) tube.Add(b.Clone());
                l.Contents.Add(tube);
            }
            l.Specials.AddRange(Specials);
            return l;
        }
    }
}
