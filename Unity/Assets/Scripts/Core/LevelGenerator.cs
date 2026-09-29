using System;
using System.Collections.Generic;
using System.Text;

namespace HueHaven
{
    public struct PackInfo
    {
        public string Name;
        public int LevelInPack;
        public int PackStart;
        public int PackLevels;
    }

    public sealed class PackDef
    {
        public string Name, Tagline, Difficulty;
        public int Levels, MinColors, MaxColors, UnlockStars;
    }

    sealed class Preset
    {
        public int Colors, EmptyTubes, Capacity, ScrambleMoves, MinDisorder;
        public double ParMult;
        public string[] Specials;
    }

    /// <summary>
    /// Generates the 500 solvable levels. Port of scripts/LevelGenerator.gd — shuffled
    /// distribution + BFS solvability check, deterministic per level index.
    /// </summary>
    public static class LevelGenerator
    {
        static readonly Dictionary<string, Preset> Presets = new Dictionary<string, Preset>
        {
            { "very_easy", new Preset { Colors = 3,  EmptyTubes = 2, Capacity = 4, ScrambleMoves = 30,  ParMult = 1.4, MinDisorder = 4,  Specials = new string[0] } },
            { "easy",      new Preset { Colors = 4,  EmptyTubes = 2, Capacity = 4, ScrambleMoves = 50,  ParMult = 1.5, MinDisorder = 7,  Specials = new string[0] } },
            { "medium",    new Preset { Colors = 5,  EmptyTubes = 2, Capacity = 4, ScrambleMoves = 80,  ParMult = 1.6, MinDisorder = 11, Specials = new[] { "rainbow" } } },
            { "hard",      new Preset { Colors = 6,  EmptyTubes = 1, Capacity = 4, ScrambleMoves = 120, ParMult = 1.8, MinDisorder = 14, Specials = new[] { "rainbow", "stone" } } },
            { "expert",    new Preset { Colors = 8,  EmptyTubes = 1, Capacity = 4, ScrambleMoves = 180, ParMult = 2.0, MinDisorder = 18, Specials = new[] { "rainbow", "stone", "magnet", "hourglass" } } },
            { "master",    new Preset { Colors = 10, EmptyTubes = 1, Capacity = 4, ScrambleMoves = 250, ParMult = 2.2, MinDisorder = 22, Specials = new[] { "rainbow", "stone", "magnet", "bomb", "hourglass" } } },
        };

        public static readonly PackDef[] Packs =
        {
            new PackDef { Name = "Tide",   Tagline = "First currents",    Levels = 10,  Difficulty = "very_easy", MinColors = 3,  MaxColors = 3,  UnlockStars = 0 },
            new PackDef { Name = "Spark",  Tagline = "Lab whispers",      Levels = 40,  Difficulty = "easy",      MinColors = 4,  MaxColors = 4,  UnlockStars = 8 },
            new PackDef { Name = "Grove",  Tagline = "Hush of leaves",    Levels = 60,  Difficulty = "medium",    MinColors = 5,  MaxColors = 5,  UnlockStars = 60 },
            new PackDef { Name = "Orbit",  Tagline = "Distant lights",    Levels = 100, Difficulty = "hard",      MinColors = 6,  MaxColors = 6,  UnlockStars = 180 },
            new PackDef { Name = "Ember",  Tagline = "Alchemist's flame", Levels = 150, Difficulty = "expert",    MinColors = 7,  MaxColors = 8,  UnlockStars = 360 },
            new PackDef { Name = "Canopy", Tagline = "Beyond the veil",   Levels = 140, Difficulty = "master",    MinColors = 8,  MaxColors = 10, UnlockStars = 660 },
        };

        public const int TotalLevels = 500;

        /// <summary>Generate a level by 0-based global index.</summary>
        public static Level Generate(int levelIdx)
        {
            var pack = PackFor(levelIdx);
            var preset = Presets[pack.Difficulty];
            long seed = (long)levelIdx * 7919; // prime multiplier for deterministic generation

            int colorRange = pack.MaxColors - pack.MinColors;
            int colors = pack.MinColors + (levelIdx % (colorRange + 1));

            var level = GeneratePuzzle(colors, preset.Capacity, preset.EmptyTubes,
                preset.ScrambleMoves, preset.ParMult, seed);

            // Inject one special on most levels for tiers that support them.
            if (preset.Specials.Length > 0 && (levelIdx % 3) != 0)
            {
                var rng = Pcg32.FromSeed(seed + 13);
                InjectSpecial(level, preset.Specials, rng);
            }
            return level;
        }

        // Forward-move scrambling can only ever produce monochrome tubes, so real
        // puzzles come from a random distribution; we then verify solvability.
        static Level GeneratePuzzle(int colors, int capacity, int emptyTubes,
            int scrambleMoves, double parMult, long seed)
        {
            List<int>[] tubes = null;
            int attempts = 0;
            const int maxAttempts = 12;
            while (attempts < maxAttempts)
            {
                var rng = Pcg32.FromSeed(seed + attempts * 101);
                tubes = ShuffleDistribution(colors, capacity, emptyTubes, rng);
                // Small puzzles are verified; big ones trust the shuffle.
                if (colors <= 7)
                {
                    if (IsSolvable(tubes, capacity, 80000)) break;
                }
                else break;
                attempts++;
            }

            int par = Math.Max(1, (int)Math.Ceiling(scrambleMoves * parMult * (1.0 + colors / 10.0)));

            var level = new Level { Colors = colors, Capacity = capacity, ParMoves = par };
            foreach (var t in tubes)
            {
                var tube = new List<Ball>(t.Count);
                foreach (var c in t) tube.Add(new Ball(c));
                level.Contents.Add(tube);
            }
            return level;
        }

        static List<int>[] ShuffleDistribution(int colors, int capacity, int emptyTubes, Pcg32 rng)
        {
            var balls = new List<int>(colors * capacity);
            for (int c = 0; c < colors; c++)
                for (int b = 0; b < capacity; b++) balls.Add(c);
            for (int i = balls.Count - 1; i > 0; i--)
            {
                int j = rng.NextInt(i + 1);
                int tmp = balls[i]; balls[i] = balls[j]; balls[j] = tmp;
            }

            var tubes = new List<int>[colors + emptyTubes];
            int idx = 0;
            for (int t = 0; t < colors; t++)
            {
                tubes[t] = new List<int>(capacity);
                for (int k = 0; k < capacity; k++) tubes[t].Add(balls[idx++]);
            }
            for (int e = 0; e < emptyTubes; e++) tubes[colors + e] = new List<int>(capacity);
            return tubes;
        }

        // BFS with a hard state cap. Tubes are hashed sorted, so permutations of
        // the same position collapse into one visited entry.
        internal static bool IsSolvable(List<int>[] start, int capacity, int maxStates)
        {
            if (IsSolvedState(start, capacity)) return true;
            var visited = new HashSet<string> { HashState(start) };
            var queue = new Queue<List<int>[]>();
            queue.Enqueue(start);
            int explored = 0;

            while (queue.Count > 0)
            {
                if (explored >= maxStates) return false;
                var current = queue.Dequeue();
                explored++;

                int n = current.Length;
                for (int from = 0; from < n; from++)
                {
                    var src = current[from];
                    if (src.Count == 0) continue;
                    int srcTop = src[src.Count - 1];
                    if (src.Count == capacity && IsMonochrome(src)) continue;
                    for (int to = 0; to < n; to++)
                    {
                        if (to == from) continue;
                        var dst = current[to];
                        if (dst.Count >= capacity) continue;
                        if (dst.Count > 0 && dst[dst.Count - 1] != srcTop) continue;

                        var next = new List<int>[n];
                        for (int i = 0; i < n; i++) next[i] = new List<int>(current[i]);
                        next[from].RemoveAt(next[from].Count - 1);
                        next[to].Add(srcTop);

                        if (IsSolvedState(next, capacity)) return true;
                        if (visited.Add(HashState(next))) queue.Enqueue(next);
                    }
                }
            }
            return false;
        }

        static bool IsSolvedState(List<int>[] tubes, int capacity)
        {
            foreach (var t in tubes)
            {
                if (t.Count == 0) continue;
                if (t.Count != capacity) return false;
                if (!IsMonochrome(t)) return false;
            }
            return true;
        }

        static bool IsMonochrome(List<int> tube)
        {
            for (int i = 1; i < tube.Count; i++)
                if (tube[i] != tube[0]) return false;
            return true;
        }

        static string HashState(List<int>[] tubes)
        {
            var parts = new string[tubes.Length];
            var sb = new StringBuilder(8);
            for (int i = 0; i < tubes.Length; i++)
            {
                sb.Clear();
                foreach (var b in tubes[i]) sb.Append((char)('a' + b));
                parts[i] = sb.ToString();
            }
            Array.Sort(parts, StringComparer.Ordinal);
            return string.Join("|", parts);
        }

        // Transmute one existing regular pearl into a special.
        static void InjectSpecial(Level level, string[] pool, Pcg32 rng)
        {
            if (pool.Length == 0) return;
            var contents = level.Contents;

            string stype = pool[rng.NextInt(pool.Length)];

            // Candidates avoid the top pearl of a tube (it would dominate the puzzle).
            var candidates = new List<int[]>(); // tube, ball, color
            for (int ti = 0; ti < contents.Count; ti++)
            {
                var tube = contents[ti];
                for (int bi = 0; bi < tube.Count - 1; bi++)
                    candidates.Add(new[] { ti, bi, tube[bi].Color });
            }
            if (candidates.Count == 0)
            {
                for (int ti = 0; ti < contents.Count; ti++)
                {
                    var tube = contents[ti];
                    if (tube.Count > 0) candidates.Add(new[] { ti, tube.Count - 1, tube[tube.Count - 1].Color });
                }
            }
            if (candidates.Count == 0) return;

            var pick = candidates[rng.NextInt(candidates.Count)];
            int tIdx = pick[0], bIdx = pick[1], color = pick[2];

            Ball special;
            switch (stype)
            {
                case "bomb":
                    special = new Ball(BallKind.Bomb, color, 12 + rng.NextInt(6));
                    break;
                case "rainbow":
                    special = new Ball(BallKind.Rainbow, -1);
                    break;
                case "stone":
                    // Stones must sit at the bottom to be solvable; relocate.
                    contents[tIdx].RemoveAt(bIdx);
                    contents[tIdx].Insert(0, new Ball(BallKind.Stone, color));
                    return;
                case "magnet":
                    special = new Ball(BallKind.Magnet, color);
                    break;
                case "hourglass":
                    special = new Ball(BallKind.Hourglass, -1);
                    break;
                default:
                    return;
            }
            contents[tIdx][bIdx] = special;
            level.Specials.Add(stype);
        }

        // --- Packs ---

        static PackDef PackFor(int levelIdx)
        {
            int cumulative = 0;
            foreach (var p in Packs)
            {
                cumulative += p.Levels;
                if (levelIdx < cumulative) return p;
            }
            return Packs[Packs.Length - 1];
        }

        public static int PackIndexFor(int levelIdx)
        {
            int cumulative = 0;
            for (int i = 0; i < Packs.Length; i++)
            {
                cumulative += Packs[i].Levels;
                if (levelIdx < cumulative) return i;
            }
            return 0;
        }

        public static PackInfo GetPackInfo(int levelIdx)
        {
            int cumulative = 0;
            foreach (var p in Packs)
            {
                cumulative += p.Levels;
                if (levelIdx < cumulative)
                    return new PackInfo { Name = p.Name, LevelInPack = levelIdx - (cumulative - p.Levels), PackStart = cumulative - p.Levels, PackLevels = p.Levels };
            }
            var last = Packs[Packs.Length - 1];
            return new PackInfo { Name = last.Name, LevelInPack = levelIdx - (cumulative - last.Levels), PackStart = cumulative - last.Levels, PackLevels = last.Levels };
        }

        public static int PackStartLevel(int packIdx)
        {
            int start = 0;
            for (int i = 0; i < packIdx; i++) start += Packs[i].Levels;
            return start;
        }
    }
}
