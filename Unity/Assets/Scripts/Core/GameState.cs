using System;
using System.Collections.Generic;

namespace HueHaven
{
    public enum EffectType { BombExplode, MagnetPull, HourglassUse }

    public struct Effect
    {
        public EffectType Type;
        public int Tube;
        public Effect(EffectType type, int tube) { Type = type; Tube = tube; }
    }

    /// <summary>
    /// Tubes, moves, undo, win detection and special-pearl rules.
    /// Straight port of scripts/GameState.gd — same rules, same tie-breaks.
    /// </summary>
    public sealed class GameState
    {
        public readonly Level Level;
        public List<List<Ball>> Tubes;
        public int MoveCount;

        readonly List<List<List<Ball>>> _undoStack = new List<List<List<Ball>>>();
        readonly List<int> _completed = new List<int>();
        List<Effect> _pending = new List<Effect>();

        public GameState(Level level)
        {
            Level = level;
            Reset();
        }

        public int Capacity => Level.Capacity;
        public bool CanUndo => _undoStack.Count > 0;

        public void Reset()
        {
            Tubes = CloneTubes(Level.Contents);
            MoveCount = 0;
            _undoStack.Clear();
            _pending = new List<Effect>();
            UpdateCompletedTubes();
        }

        static List<List<Ball>> CloneTubes(List<List<Ball>> src)
        {
            var result = new List<List<Ball>>(src.Count);
            foreach (var t in src)
            {
                var tube = new List<Ball>(t.Count);
                foreach (var b in t) tube.Add(b.Clone());
                result.Add(tube);
            }
            return result;
        }

        // --- Completion ---

        void UpdateCompletedTubes()
        {
            _completed.Clear();
            for (int i = 0; i < Tubes.Count; i++)
                if (IsTubeMonochrome(i)) _completed.Add(i);
        }

        bool IsTubeMonochrome(int idx)
        {
            var t = Tubes[idx];
            if (t.Count < Capacity) return false;
            int refColor = -1;
            foreach (var b in t)
            {
                if (b.IsStone) continue;
                if (b.IsRainbow) continue; // wildcard
                if (refColor < 0) refColor = b.Color;
                else if (b.Color != refColor) return false;
            }
            // A tube of only stones/rainbows is not a completion.
            return refColor >= 0;
        }

        // --- Movement ---

        public bool CanMove(int from, int to)
        {
            if (from == to) return false;
            var src = Tubes[from];
            var dst = Tubes[to];
            if (src.Count == 0) return false;
            if (dst.Count >= Capacity) return false;

            var srcTop = src[src.Count - 1];
            if (srcTop.IsStone) return false;

            if (dst.Count > 0)
            {
                var dstTop = dst[dst.Count - 1];
                if (dstTop.IsStone) return false;
                // Rainbow wildcards on either side accept any color.
                if (!srcTop.IsRainbow && !dstTop.IsRainbow && srcTop.Color != dstTop.Color)
                    return false;
            }
            return true;
        }

        public bool MoveBall(int from, int to)
        {
            if (!CanMove(from, to)) return false;

            // Always snapshot the full state — keeps undo bulletproof under specials.
            _undoStack.Add(CloneTubes(Tubes));

            var src = Tubes[from];
            var ball = src[src.Count - 1];
            src.RemoveAt(src.Count - 1);
            Tubes[to].Add(ball);

            OnBallPlaced(ball, to);
            TickBombs();

            MoveCount++;
            UpdateCompletedTubes();
            return true;
        }

        void OnBallPlaced(Ball ball, int to)
        {
            if (ball.Kind == BallKind.Magnet)
            {
                ResolveMagnet(to, ball.Color);
                _pending.Add(new Effect(EffectType.MagnetPull, to));
            }
            else if (ball.Kind == BallKind.Hourglass)
            {
                RefillBombs(5);
                _pending.Add(new Effect(EffectType.HourglassUse, to));
            }
        }

        void ResolveMagnet(int to, int color)
        {
            if (color < 0) return;
            bool changed = true;
            while (changed && Tubes[to].Count < Capacity)
            {
                changed = false;
                for (int i = 0; i < Tubes.Count; i++)
                {
                    if (i == to) continue;
                    var src = Tubes[i];
                    if (src.Count == 0) continue;
                    var top = src[src.Count - 1];
                    if (top.IsStone || top.IsSpecial) continue;
                    if (top.Color == color)
                    {
                        src.RemoveAt(src.Count - 1);
                        Tubes[to].Add(top);
                        changed = true;
                        if (Tubes[to].Count >= Capacity) return;
                    }
                }
            }
        }

        void TickBombs()
        {
            for (int i = 0; i < Tubes.Count; i++)
            {
                var tube = Tubes[i];
                for (int j = 0; j < tube.Count; j++)
                {
                    var b = tube[j];
                    if (b.Kind != BallKind.Bomb) continue;
                    b.Meta = Math.Max(0, b.Meta - 1);
                    if (b.Meta <= 0)
                    {
                        ExplodeBomb(i, j);
                        _pending.Add(new Effect(EffectType.BombExplode, i));
                        return; // tubes mutated; one explosion per move keeps things sane
                    }
                }
            }
        }

        void ExplodeBomb(int tubeIdx, int ballIdx)
        {
            // Remove the bomb and scramble what is left in that tube,
            // deterministically from (move count, tube index).
            var tube = Tubes[tubeIdx];
            tube.RemoveAt(ballIdx);
            var rng = Pcg32.FromSeed((long)(MoveCount + 1) * 31 + tubeIdx);
            for (int k = tube.Count - 1; k > 0; k--)
            {
                int swap = rng.NextInt(k + 1);
                var tmp = tube[k];
                tube[k] = tube[swap];
                tube[swap] = tmp;
            }
        }

        void RefillBombs(int addMoves)
        {
            foreach (var tube in Tubes)
                foreach (var b in tube)
                    if (b.Kind == BallKind.Bomb) b.Meta += addMoves;
        }

        // --- Undo ---

        public bool Undo()
        {
            if (_undoStack.Count == 0) return false;
            Tubes = _undoStack[_undoStack.Count - 1];
            _undoStack.RemoveAt(_undoStack.Count - 1);
            MoveCount = Math.Max(0, MoveCount - 1);
            UpdateCompletedTubes();
            return true;
        }

        // --- Queries ---

        public bool IsTubeComplete(int idx) => _completed.Contains(idx);

        public bool IsLevelWon()
        {
            for (int i = 0; i < Tubes.Count; i++)
            {
                var t = Tubes[i];
                if (t.Count == 0 || IsTubeMonochrome(i)) continue;
                // Allow all-stone tubes (rare) to pass.
                bool allStone = true;
                foreach (var b in t) if (!b.IsStone) { allStone = false; break; }
                if (!allStone) return false;
            }
            return true;
        }

        /// <summary>True if at least one legal move exists.</summary>
        public bool HasAnyMove()
        {
            int n = Tubes.Count;
            for (int from = 0; from < n; from++)
            {
                if (Tubes[from].Count == 0) continue;
                if (IsTubeMonochrome(from)) continue;
                for (int to = 0; to < n; to++)
                    if (CanMove(from, to)) return true;
            }
            return false;
        }

        // --- Hint ---

        /// <summary>Best (from, to) pair, or (-1, -1) when there is no move.</summary>
        public (int from, int to) FindHint()
        {
            int n = Tubes.Count;
            int bestFrom = -1, bestTo = -1, bestScore = -999;

            for (int from = 0; from < n; from++)
            {
                var src = Tubes[from];
                if (src.Count == 0) continue;
                if (IsTubeMonochrome(from)) continue;
                var srcTop = src[src.Count - 1];
                if (srcTop.IsStone) continue;
                int srcColor = srcTop.Color;

                for (int to = 0; to < n; to++)
                {
                    if (to == from) continue;
                    if (!CanMove(from, to)) continue;

                    var dst = Tubes[to];
                    int score = 0;

                    if (dst.Count > 0)
                    {
                        score += 10;
                        bool allSame = true;
                        foreach (var b in dst)
                        {
                            if (b.IsStone) continue;
                            if (b.Color != srcColor && !b.IsRainbow) { allSame = false; break; }
                        }
                        if (allSame)
                        {
                            score += 5;
                            if (dst.Count == Capacity - 1) score += 100;
                        }
                    }

                    if (src.Count == 1) score += 3;
                    if (dst.Count == 0 && src.Count > 1) score -= 5;

                    if (score > bestScore)
                    {
                        bestScore = score;
                        bestFrom = from;
                        bestTo = to;
                    }
                }
            }
            return (bestFrom, bestTo);
        }

        // --- Star rating ---

        public int GetStarRating()
        {
            int par = Level.ParMoves;
            if (MoveCount <= par) return 3;
            if (MoveCount <= par * 2) return 2;
            return 1;
        }

        /// <summary>Consume queued side-effect events (the view reads + clears these).</summary>
        public List<Effect> TakeEffects()
        {
            var e = _pending;
            _pending = new List<Effect>();
            return e;
        }
    }
}
