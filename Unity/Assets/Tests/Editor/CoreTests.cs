using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;

namespace HueHaven.Tests
{
    /// <summary>Rules + level-generation tests. Core code has no engine dependency, so these also run outside Unity.</summary>
    public class CoreTests
    {
        // ---- helpers ----------------------------------------------------------------

        // '0'-'9' regular colour, R rainbow, S stone, M magnet(color 0), H hourglass, B bomb(color 1, 2 moves)
        static Level Mk(params string[] tubes)
        {
            var l = new Level { Colors = 3, Capacity = 4, ParMoves = 5 };
            foreach (var s in tubes)
            {
                var t = new List<Ball>();
                foreach (char ch in s)
                {
                    switch (ch)
                    {
                        case 'R': t.Add(new Ball(BallKind.Rainbow, -1)); break;
                        case 'S': t.Add(new Ball(BallKind.Stone, 0)); break;
                        case 'M': t.Add(new Ball(BallKind.Magnet, 0)); break;
                        case 'H': t.Add(new Ball(BallKind.Hourglass, -1)); break;
                        case 'B': t.Add(new Ball(BallKind.Bomb, 1, 2)); break;
                        default: t.Add(new Ball(ch - '0')); break;
                    }
                }
                l.Contents.Add(t);
            }
            return l;
        }

        static string Dump(GameState g)
        {
            return string.Join("|", g.Tubes.Select(t => string.Join(",", t.Select(b => (int)b.Kind + ":" + b.Color + ":" + b.Meta)))) + "#" + g.MoveCount;
        }

        // ---- RNG --------------------------------------------------------------------

        [Test]
        public void Pcg32_MatchesReferenceVector()
        {
            // pcg32-demo, seed 42 / stream 54
            var r = new Pcg32(42UL, 54UL);
            uint[] expected = { 0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e };
            foreach (var e in expected) Assert.AreEqual(e, r.NextUInt());
        }

        // ---- levels -----------------------------------------------------------------

        [Test]
        public void AllLevels_AreWellFormed()
        {
            for (int i = 0; i < LevelGenerator.TotalLevels; i++)
            {
                var lv = LevelGenerator.Generate(i);
                Assert.AreEqual(4, lv.Capacity, "capacity @" + i);
                Assert.AreEqual(lv.Colors * 4, lv.Contents.Sum(t => t.Count), "ball count @" + i);
                Assert.IsTrue(lv.Contents.All(t => t.Count <= lv.Capacity), "overfull tube @" + i);
                Assert.GreaterOrEqual(lv.ParMoves, 1, "par @" + i);

                var gs = new GameState(lv);
                Assert.IsFalse(gs.IsLevelWon(), "already solved @" + i);
                Assert.IsTrue(gs.HasAnyMove(), "no opening move @" + i);
            }
        }

        [Test]
        public void Generation_IsDeterministic()
        {
            for (int i = 0; i < LevelGenerator.TotalLevels; i += 37)
                Assert.AreEqual(Signature(LevelGenerator.Generate(i)), Signature(LevelGenerator.Generate(i)));
        }

        static string Signature(Level l)
        {
            return string.Join("|", l.Contents.Select(t => string.Join(",", t.Select(b => b.Kind + ":" + b.Color + ":" + b.Meta))));
        }

        [Test]
        public void Packs_CoverAllLevels()
        {
            Assert.AreEqual(LevelGenerator.TotalLevels, LevelGenerator.Packs.Sum(p => p.Levels));
            var info = LevelGenerator.GetPackInfo(10); // first level of the second pack
            Assert.AreEqual("Spark", info.Name);
            Assert.AreEqual(0, info.LevelInPack);
            Assert.AreEqual(1, LevelGenerator.PackIndexFor(10));
        }

        // ---- rules ------------------------------------------------------------------

        [Test]
        public void Move_RequiresMatchingTopOrEmpty()
        {
            var g = new GameState(Mk("012", "0", ""));
            Assert.IsFalse(g.CanMove(0, 1)); // 2 onto 0
            Assert.IsTrue(g.CanMove(0, 2));  // into empty
            Assert.IsFalse(g.CanMove(0, 0)); // same tube
            Assert.IsFalse(g.CanMove(2, 0)); // from empty
        }

        [Test]
        public void Move_RespectsCapacity()
        {
            var g = new GameState(Mk("1111", "1"));
            Assert.IsFalse(g.CanMove(1, 0));
        }

        [Test]
        public void Rainbow_MatchesAnything()
        {
            var g = new GameState(Mk("01R", "2"));
            Assert.IsTrue(g.CanMove(0, 1));
        }

        [Test]
        public void Stone_IsImmovableAndBlocking()
        {
            var g = new GameState(Mk("S", "0"));
            Assert.IsFalse(g.CanMove(0, 1));
            Assert.IsFalse(g.CanMove(1, 0));
        }

        [Test]
        public void Magnet_PullsMatchingTopsUntilFull_LowestTubeFirst()
        {
            var g = new GameState(Mk("0M", "0100", "00"));
            Assert.IsTrue(g.MoveBall(0, 2));
            Assert.AreEqual(4, g.Tubes[2].Count);
            Assert.AreEqual(0, g.Tubes[0].Count);
            Assert.AreEqual(4, g.Tubes[1].Count);
            Assert.IsTrue(g.TakeEffects().Any(e => e.Type == EffectType.MagnetPull));
        }

        [Test]
        public void Hourglass_AddsFiveMovesToBombs()
        {
            var g = new GameState(Mk("1B", "12", "", "H"));
            Assert.IsTrue(g.MoveBall(3, 2)); // +5 then this move's tick: 2 + 5 - 1
            Assert.AreEqual(6, g.Tubes[0][1].Meta);
        }

        [Test]
        public void Bomb_ExplodesWhenTimerHitsZero_AndUndoRestoresIt()
        {
            var g = new GameState(Mk("1B", "", "2"));
            Assert.IsTrue(g.MoveBall(2, 1));
            Assert.AreEqual(1, g.Tubes[0][1].Meta);
            Assert.IsTrue(g.MoveBall(1, 2));
            Assert.AreEqual(1, g.Tubes[0].Count);
            Assert.IsTrue(g.TakeEffects().Any(e => e.Type == EffectType.BombExplode));

            Assert.IsTrue(g.Undo());
            Assert.AreEqual(2, g.Tubes[0].Count);
            Assert.AreEqual(1, g.Tubes[0][1].Meta);
        }

        [Test]
        public void WinAndStars()
        {
            var solved = new GameState(Mk("0000", "1111", "2222"));
            Assert.IsTrue(solved.IsLevelWon());
            Assert.AreEqual(3, solved.GetStarRating());

            var open = new GameState(Mk("0000", "1112", "", "2"));
            Assert.IsFalse(open.IsLevelWon());

            var g = new GameState(Mk("01", "1", "0")); // par 5
            g.MoveCount = 5; Assert.AreEqual(3, g.GetStarRating());
            g.MoveCount = 10; Assert.AreEqual(2, g.GetStarRating());
            g.MoveCount = 11; Assert.AreEqual(1, g.GetStarRating());
        }

        [Test]
        public void Hint_PrefersFinishingATube()
        {
            var g = new GameState(Mk("0000", "1112", "", "2"));
            var hint = g.FindHint();
            Assert.AreEqual((1, 3), hint); // 2 onto the lone 2 beats parking it in the empty tube
        }

        [Test]
        public void HasAnyMove_FalseWhenDeadEnd()
        {
            var dead = new GameState(Mk("0123", "1230", "2301", "3012"));
            Assert.IsFalse(dead.HasAnyMove());
        }

        [Test]
        public void RandomPlay_KeepsInvariants_AndUndoIsExact()
        {
            var rng = new Random(1);
            for (int lvl = 0; lvl < LevelGenerator.TotalLevels; lvl += 7)
            {
                var gs = new GameState(LevelGenerator.Generate(lvl));
                for (int step = 0; step < 300; step++)
                {
                    int from = rng.Next(gs.Tubes.Count), to = rng.Next(gs.Tubes.Count);
                    string before = Dump(gs);
                    if (gs.CanMove(from, to))
                    {
                        Assert.IsTrue(gs.MoveBall(from, to));
                        gs.TakeEffects();
                        if (rng.Next(3) == 0)
                        {
                            Assert.IsTrue(gs.Undo());
                            Assert.AreEqual(before, Dump(gs), "undo not exact @level " + lvl);
                        }
                    }
                    else Assert.IsFalse(gs.MoveBall(from, to));
                    Assert.IsTrue(gs.Tubes.All(t => t.Count <= gs.Capacity));
                }
            }
        }
    }
}
