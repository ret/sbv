-----------------------------------------------------------------------------
-- |
-- Module      :  TestSuite.Basics.ArithSolver
-- Copyright   :  (c) Levent Erkok
-- License     :  BSD3
-- Maintainer  :  erkokl@gmail.com
-- Stability   :  experimental
--
-- Test suite for basic non-concrete arithmetic, i.e., testing all
-- basic arithmetic reasoning using an SMT solver without any
-- constant folding.
-----------------------------------------------------------------------------

{-# LANGUAGE Rank2Types    #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE CPP           #-}

module TestSuite.Basics.ArithSolver(testSuite) where

import Data.SBV

import SBVTest

ghcBitSize :: Bits a => a -> Int
#if __GLASGOW_HASKELL__ >= 708
ghcBitSize x = maybe (error "SBV.ghcBitSize: Unexpected non-finite usage!") id (bitSizeMaybe x)
#else
ghcBitSize = bitSize
#endif

-- Test suite
testSuite :: SBVTestSuite
testSuite = mkTestSuite $ \_ -> test $
        genReals
     ++ genFloats
     ++ genDoubles
     ++ genQRems
     ++ genBinTest  True   "+"                (+)
     ++ genBinTest  True   "-"                (-)
     ++ genBinTest  True   "*"                (*)
     ++ genUnTest   True   "negate"           negate
     ++ genUnTest   True   "abs"              abs
     ++ genUnTest   True   "signum"           signum
     ++ genBinTest  False  ".&."              (.&.)
     ++ genBinTest  False  ".|."              (.|.)
     ++ genBoolTest        "<"                (<)  (.<)
     ++ genBoolTest        "<="               (<=) (.<=)
     ++ genBoolTest        ">"                (>)  (.>)
     ++ genBoolTest        ">="               (>=) (.>=)
     ++ genBoolTest        "=="               (==) (.==)
     ++ genBoolTest        "/="               (/=) (./=)
     ++ genBinTest  False  "xor"              xor
     ++ genUnTest   False  "complement"       complement
     ++ genIntTest         "shift"            shift
     ++ genIntTest         "rotate"           rotate
     ++ genIntTestS False  "setBit"           setBit
     ++ genIntTestS False  "clearBit"         clearBit
     ++ genIntTestS False  "complementBit"    complementBit
     ++ genIntTest         "shift"            shift
     ++ genIntTestS True   "shiftL"           shiftL
     ++ genIntTestS True   "shiftR"           shiftR
     ++ genIntTest         "rotate"           rotate
     ++ genIntTestS True   "rotateL"          rotateL
     ++ genIntTestS True   "rotateR"          rotateR
     ++ genBlasts
     ++ genCasts


genBinTest :: Bool -> String -> (forall a. (Num a, Bits a) => a -> a -> a) -> [Test]
genBinTest unboundedOK nm op = map mkTest $  [(show x, show y, mkThm2 x y (x `op` y)) | x <- w8s,  y <- w8s ]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- w16s, y <- w16s]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- w32s, y <- w32s]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- w64s, y <- w64s]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i8s,  y <- i8s ]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i16s, y <- i16s]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i32s, y <- i32s]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i64s, y <- i64s]
                                          ++ [(show x, show y, mkThm2 x y (x `op` y)) | unboundedOK, x <- iUBs, y <- iUBs]
  where mkTest (x, y, t) = "genBinTest.arithmetic-" ++ nm ++ "." ++ x ++ "_" ++ y  ~: assert t
        mkThm2 x y r = isThm $ do [a, b] <- mapM free ["x", "y"]
                                  constrain $ a .== literal x
                                  constrain $ b .== literal y
                                  return $ literal r .== a `op` b

genBoolTest :: String -> (forall a. Ord a => a -> a -> Bool) -> (forall a. OrdSymbolic a => a -> a -> SBool) -> [Test]
genBoolTest nm op opS = map mkTest $  [(show x, show y, mkThm2 x y (x `op` y)) | x <- w8s,  y <- w8s ]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- w16s, y <- w16s]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- w32s, y <- w32s]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- w64s, y <- w64s]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i8s,  y <- i8s ]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i16s, y <- i16s]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i32s, y <- i32s]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- i64s, y <- i64s]
                                   ++ [(show x, show y, mkThm2 x y (x `op` y)) | x <- iUBs, y <- iUBs]
  where mkTest (x, y, t) = "genBoolTest.arithmetic-" ++ nm ++ "." ++ x ++ "_" ++ y  ~: assert t
        mkThm2 x y r = isThm $ do [a, b] <- mapM free ["x", "y"]
                                  constrain $ a .== literal x
                                  constrain $ b .== literal y
                                  return $ literal r .== a `opS` b

genUnTest :: Bool -> String -> (forall a. (Num a, Bits a) => a -> a) -> [Test]
genUnTest unboundedOK nm op = map mkTest $  [(show x, mkThm x (op x)) | x <- w8s ]
                                         ++ [(show x, mkThm x (op x)) | x <- w16s]
                                         ++ [(show x, mkThm x (op x)) | x <- w32s]
                                         ++ [(show x, mkThm x (op x)) | x <- w64s]
                                         ++ [(show x, mkThm x (op x)) | x <- i8s ]
                                         ++ [(show x, mkThm x (op x)) | x <- i16s]
                                         ++ [(show x, mkThm x (op x)) | x <- i32s]
                                         ++ [(show x, mkThm x (op x)) | x <- i64s]
                                         ++ [(show x, mkThm x (op x)) | unboundedOK, x <- iUBs]
  where mkTest (x, t) = "genUnTest.arithmetic-" ++ nm ++ "." ++ x ~: assert t
        mkThm x r = isThm $ do a <- free "x"
                               constrain $ a .== literal x
                               return $ literal r .== op a

genIntTest :: String -> (forall a. (Num a, Bits a) => a -> Int -> a) -> [Test]
genIntTest nm op = map mkTest $  [("u8",  show x, show y, mkThm2 x y (x `op` y)) | x <- w8s,  y <- is]
                              ++ [("u16", show x, show y, mkThm2 x y (x `op` y)) | x <- w16s, y <- is]
                              ++ [("u32", show x, show y, mkThm2 x y (x `op` y)) | x <- w32s, y <- is]
                              ++ [("u64", show x, show y, mkThm2 x y (x `op` y)) | x <- w64s, y <- is]
                              ++ [("s8",  show x, show y, mkThm2 x y (x `op` y)) | x <- i8s,  y <- is]
                              ++ [("s16", show x, show y, mkThm2 x y (x `op` y)) | x <- i16s, y <- is]
                              ++ [("s32", show x, show y, mkThm2 x y (x `op` y)) | x <- i32s, y <- is]
                              ++ [("s64", show x, show y, mkThm2 x y (x `op` y)) | x <- i64s, y <- is]
                              ++ [("iUB", show x, show y, mkThm2 x y (x `op` y)) | x <- iUBs, y <- is]
  where mkTest (l, x, y, t) = "genIntTest.arithmetic-" ++ nm ++ "." ++ l ++ "_" ++ x ++ "_" ++ y ~: assert t
        is = [-10 .. 10]
        mkThm2 x y r = isThm $ do a <- free "x"
                                  constrain $ a .== literal x
                                  return $ literal r .== a `op` y


genIntTestS :: Bool -> String -> (forall a. (Num a, Bits a) => a -> Int -> a) -> [Test]
genIntTestS unboundedOK nm op = map mkTest $  [("u8",  show x, show y, mkThm2 x y (x `op` y)) | x <- w8s,  y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("u16", show x, show y, mkThm2 x y (x `op` y)) | x <- w16s, y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("u32", show x, show y, mkThm2 x y (x `op` y)) | x <- w32s, y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("u64", show x, show y, mkThm2 x y (x `op` y)) | x <- w64s, y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("s8",  show x, show y, mkThm2 x y (x `op` y)) | x <- i8s,  y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("s16", show x, show y, mkThm2 x y (x `op` y)) | x <- i16s, y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("s32", show x, show y, mkThm2 x y (x `op` y)) | x <- i32s, y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("s64", show x, show y, mkThm2 x y (x `op` y)) | x <- i64s, y <- [0 .. (ghcBitSize x - 1)]]
                                           ++ [("iUB", show x, show y, mkThm2 x y (x `op` y)) | unboundedOK, x <- iUBs, y <- [0 .. 10]]
  where mkTest (l, x, y, t) = "genIntTestS.arithmetic-" ++ nm ++ "." ++ l ++ "_" ++ x ++ "_" ++ y ~: assert t
        mkThm2 x y r = isThm $ do a <- free "x"
                                  constrain $ a .== literal x
                                  return $ literal r .== a `op` y

genBlasts :: [Test]
genBlasts = map mkTest $  [(show x, mkThm fromBitsLE blastLE x) | x <- w8s ]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- w8s ]
                       ++ [(show x, mkThm fromBitsLE blastLE x) | x <- i8s ]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- i8s ]
                       ++ [(show x, mkThm fromBitsLE blastLE x) | x <- w16s]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- w16s]
                       ++ [(show x, mkThm fromBitsLE blastLE x) | x <- i16s]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- i16s]
                       ++ [(show x, mkThm fromBitsLE blastLE x) | x <- w32s]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- w32s]
                       ++ [(show x, mkThm fromBitsLE blastLE x) | x <- i32s]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- i32s]
                       ++ [(show x, mkThm fromBitsLE blastLE x) | x <- w64s]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- w64s]
                       ++ [(show x, mkThm fromBitsLE blastLE x) | x <- i64s]
                       ++ [(show x, mkThm fromBitsBE blastBE x) | x <- i64s]
  where mkTest (x, t) = "genBlasts.blast-" ++ show x ~: assert t
        mkThm from to v = isThm $ do a <- free "x"
                                     constrain $ a .== literal v
                                     return $ a .== from (to a)

genCasts :: [Test]
genCasts = map mkTest $  [(show x, mkThm unsignCast signCast x) | x <- w8s ]
                      ++ [(show x, mkThm unsignCast signCast x) | x <- w16s]
                      ++ [(show x, mkThm unsignCast signCast x) | x <- w32s]
                      ++ [(show x, mkThm unsignCast signCast x) | x <- w64s]
                      ++ [(show x, mkThm signCast unsignCast x) | x <- i8s ]
                      ++ [(show x, mkThm signCast unsignCast x) | x <- i16s]
                      ++ [(show x, mkThm signCast unsignCast x) | x <- i8s ]
                      ++ [(show x, mkThm signCast unsignCast x) | x <- i16s]
                      ++ [(show x, mkThm signCast unsignCast x) | x <- i32s]
                      ++ [(show x, mkThm signCast unsignCast x) | x <- i64s]
                      ++ [(show x, mkFEq signCast   (fromBitsLE . blastLE) x) | x <- w8s ]
                      ++ [(show x, mkFEq signCast   (fromBitsLE . blastLE) x) | x <- w16s]
                      ++ [(show x, mkFEq signCast   (fromBitsLE . blastLE) x) | x <- w32s]
                      ++ [(show x, mkFEq signCast   (fromBitsLE . blastLE) x) | x <- w64s]
                      ++ [(show x, mkFEq unsignCast (fromBitsLE . blastLE) x) | x <- i8s ]
                      ++ [(show x, mkFEq unsignCast (fromBitsLE . blastLE) x) | x <- i16s]
                      ++ [(show x, mkFEq unsignCast (fromBitsLE . blastLE) x) | x <- i32s]
                      ++ [(show x, mkFEq unsignCast (fromBitsLE . blastLE) x) | x <- i64s]
  where mkTest (x, t) = "genCasts.cast-" ++ x ~: assert t
        mkThm from to v = isThm $ do a <- free "x"
                                     constrain $ a .== literal v
                                     return $ a .== from (to a)
        mkFEq f g v = isThm $ do a <- free "x"
                                 constrain $ a .== literal v
                                 return $ f a .== g a

genReals :: [Test]
genReals = map mkTest $  [("+",  show x, show y, mkThm2 (+)   x y (x +  y)) | x <- rs, y <- rs        ]
                      ++ [("-",  show x, show y, mkThm2 (-)   x y (x -  y)) | x <- rs, y <- rs        ]
                      ++ [("*",  show x, show y, mkThm2 (*)   x y (x *  y)) | x <- rs, y <- rs        ]
                      ++ [("/",  show x, show y, mkThm2 (/)   x y (x /  y)) | x <- rs, y <- rs, y /= 0]
                      ++ [("<",  show x, show y, mkThm2 (.<)  x y (x <  y)) | x <- rs, y <- rs        ]
                      ++ [("<=", show x, show y, mkThm2 (.<=) x y (x <= y)) | x <- rs, y <- rs        ]
                      ++ [(">",  show x, show y, mkThm2 (.>)  x y (x >  y)) | x <- rs, y <- rs        ]
                      ++ [(">=", show x, show y, mkThm2 (.>=) x y (x >= y)) | x <- rs, y <- rs        ]
                      ++ [("==", show x, show y, mkThm2 (.==) x y (x == y)) | x <- rs, y <- rs        ]
                      ++ [("/=", show x, show y, mkThm2 (./=) x y (x /= y)) | x <- rs, y <- rs        ]
  where mkTest (nm, x, y, t) = "genReals.arithmetic-" ++ nm ++ "." ++ x ++ "_" ++ y  ~: assert t
        mkThm2 op x y r = isThm $ do [a, b] <- mapM free ["x", "y"]
                                     constrain $ a .== literal x
                                     constrain $ b .== literal y
                                     return $ literal r .== a `op` b

genFloats :: [Test]
genFloats = genIEEE754 "genFloats" fs

genDoubles :: [Test]
genDoubles = genIEEE754 "genDoubles" ds

genIEEE754 :: (IEEEFloating a, Show a, Ord a) => String -> [a] -> [Test]
genIEEE754 origin vs = map tst1 uns ++ map tst2 bins ++ map tst1 preds
  where uns =     [("abs",               show x,         mkThm1        abs                   x   (abs x))                | x <- vs]
               ++ [("negate",            show x,         mkThm1        negate                x   (negate x))             | x <- vs]
               -- TODO: Remove NaNs in signum, skipping over NaN due to GHC bug. GitHub Issue #101
               ++ [("signum",            show x,         mkThm1        signum                x   (signum x))             | x <- vs, not (isNaN x)]
               ++ [("fpAbs",             show x,         mkThm1        fpAbs                 x   (abs x))                | x <- vs]
               ++ [("fpNeg",             show x,         mkThm1        fpNeg                 x   (negate x))             | x <- vs]
               ++ [("fpSqrt",            show x,         mkThm1        (m fpSqrt)            x   (sqrt   x))             | x <- vs]
               ++ [("fpRoundToIntegral", show x,         mkThm1        (m fpRoundToIntegral) x   (fpRoundToIntegralH x)) | x <- vs]

        bins =    [("+",      show x, show y, mkThm2        (+)       x y (x +  y))   | x <- vs, y <- vs]
               ++ [("-",      show x, show y, mkThm2        (-)       x y (x -  y))   | x <- vs, y <- vs]
               ++ [("*",      show x, show y, mkThm2        (*)       x y (x *  y))   | x <- vs, y <- vs]
               ++ [("/",      show x, show y, mkThm2        (/)       x y (x /  y))   | x <- vs, y <- vs]
               ++ [("<",      show x, show y, mkThm2C False (.<)      x y (x <  y))   | x <- vs, y <- vs]
               ++ [("<=",     show x, show y, mkThm2C False (.<=)     x y (x <= y))   | x <- vs, y <- vs]
               ++ [(">",      show x, show y, mkThm2C False (.>)      x y (x >  y))   | x <- vs, y <- vs]
               ++ [(">=",     show x, show y, mkThm2C False (.>=)     x y (x >= y))   | x <- vs, y <- vs]
               ++ [("==",     show x, show y, mkThm2C False (.==)     x y (x == y))   | x <- vs, y <- vs]
               ++ [("/=",     show x, show y, mkThm2C True  (./=)     x y (x /= y))   | x <- vs, y <- vs]
               -- TODO. Can't possibly test fma, unless we FFI out to C. Leave it out for the time being
               ++ [("fpAdd",          show x, show y, mkThm2        (m fpAdd)      x y ((+)            x y)) | x <- vs, y <- vs]
               ++ [("fpSub",          show x, show y, mkThm2        (m fpSub)      x y ((-)            x y)) | x <- vs, y <- vs]
               ++ [("fpMul",          show x, show y, mkThm2        (m fpMul)      x y ((*)            x y)) | x <- vs, y <- vs]
               ++ [("fpDiv",          show x, show y, mkThm2        (m fpDiv)      x y ((/)            x y)) | x <- vs, y <- vs]
               ++ [("fpMin",          show x, show y, mkThm2        fpMin          x y (minH           x y)) | x <- vs, y <- vs]
               ++ [("fpMax",          show x, show y, mkThm2        fpMax          x y (maxH           x y)) | x <- vs, y <- vs]
               ++ [("fpRem",          show x, show y, mkThm2        fpRem          x y (fpRemH         x y)) | x <- vs, y <- vs]
               ++ [("fpEqualObject",  show x, show y, mkThm2C False fpEqualObject  x y (fpEqualObjectH x y)) | x <- vs, y <- vs]

        m f = f sRoundNearestTiesToEven

        fpRoundToIntegralH :: RealFloat a => a -> a
        fpRoundToIntegralH = fromInteger . round

        fpRemH :: RealFloat a => a -> a -> a
        fpRemH x y = x - y * fromInteger (round (x / y))

        -- as opposed to the Haskell's min/max; IEEE-754 min/max follows return the "other" argument when one of the arguments is NaN
        -- and also, be careful on -0/+0
        -- TODO: Remove this when <https://ghc.haskell.org/trac/ghc/ticket/10378> is fixed.
        maxH x y
          | isNaN x                               = y
          | isNaN y                               = x
          | x > y || (x == y && isNegativeZero y) = x
          | True                                  = y
        minH x y
          | isNaN x                               = y
          | isNaN y                               = x
          | x < y || (x == y && isNegativeZero x) = x
          | True                                  = y

        preds =   [(pn,       show x,         mkThmP        ps       x   (pc x))     | (pn, ps, pc) <- predicates, x <- vs
                                                                                     -- Work around GHC bug, see issue #138
                                                                                     -- Remove the following line when fixed.
                                                                                     , not (pn == "fpIsPositiveZero" && isNegativeZero x)
                                                                                     ]
        tst2 (nm, x, y, t) = origin ++ ".arithmetic-" ++ nm ++ "." ++ x ++ "_" ++ y  ~: assert t
        tst1 (nm, x,    t) = origin ++ ".arithmetic-" ++ nm ++ "." ++ x              ~: assert t
        eqF v val
          | isNaN          val        = constrain $ fpIsNaN v
          | isNegativeZero val        = constrain $ fpIsNegativeZero v
          | val == 0                  = constrain $ fpIsPositiveZero v
          | isInfinite val && val > 0 = constrain $ fpIsInfinite v &&& fpIsPositive v
          | isInfinite val && val < 0 = constrain $ fpIsInfinite v &&& fpIsNegative v
          | True                      = constrain $ v .== literal val
        fpEqualObjectH :: RealFloat a => a -> a -> Bool
        fpEqualObjectH a b
          | isNaN a          = isNaN b
          | isNegativeZero a = isNegativeZero b
          | isNegativeZero b = isNegativeZero a
          | True             = a == b
        mkThmP op x r = isThm $ do a <- free "x"
                                   eqF a x
                                   return $ literal r .== op a
        mkThm1 op x r = isThm $ do a <- free "x"
                                   eqF a x
                                   return $ literal r `fpEqualObject` op a
        mkThm2 op x y r = isThm $ do [a, b] <- mapM free ["x", "y"]
                                     eqF a x
                                     eqF b y
                                     return $ literal r `fpEqualObject` (a `op` b)
        mkThm2C neq op x y r = isThm $ do [a, b] <- mapM free ["x", "y"]
                                          eqF a x
                                          eqF b y
                                          return $ if isNaN x || isNaN y
                                                   then (if neq then a `op` b else bnot (a `op` b))
                                                   else literal r .== a `op` b
        predicates :: (IEEEFloating a) => [(String, SBV a -> SBool, a -> Bool)]
        predicates = [ ("fpIsNormal",       fpIsNormal,        isNormalized)
                     , ("fpIsSubnormal",    fpIsSubnormal,     isDenormalized)
                     , ("fpIsZero",         fpIsZero,          (== 0))
                     , ("fpIsInfinite",     fpIsInfinite,      isInfinite)
                     , ("fpIsNaN",          fpIsNaN,           isNaN)
                     , ("fpIsNegative",     fpIsNegative,      \x -> x < 0  ||      isNegativeZero x)
                     , ("fpIsPositive",     fpIsPositive,      \x -> x >= 0 && not (isNegativeZero x))
                     , ("fpIsNegativeZero", fpIsNegativeZero,  isNegativeZero)
                     , ("fpIsPositiveZero", fpIsPositiveZero,  \x -> x == 0 && not (isNegativeZero x))
                     , ("fpIsPoint",        fpIsPoint,         \x -> not (isNaN x || isInfinite x))
                     ]
           where isNormalized x = not (isDenormalized x || isInfinite x || isNaN x)

genQRems :: [Test]
genQRems = map mkTest $  [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- w8s,  y <- w8s ]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- w16s, y <- w16s]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- w32s, y <- w32s]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- w64s, y <- w64s]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- i8s,  y <- i8s , noOverflow x y]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- i16s, y <- i16s, noOverflow x y]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- i32s, y <- i32s, noOverflow x y]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- i64s, y <- i64s, noOverflow x y]
                      ++ [("divMod",  show x, show y, mkThm2 sDivMod  x y (x `divMod'`  y)) | x <- iUBs, y <- iUBs]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- w8s,  y <- w8s ]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- w16s, y <- w16s]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- w32s, y <- w32s]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- w64s, y <- w64s]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- i8s,  y <- i8s , noOverflow x y]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- i16s, y <- i16s, noOverflow x y]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- i32s, y <- i32s, noOverflow x y]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- i64s, y <- i64s, noOverflow x y]
                      ++ [("quotRem", show x, show y, mkThm2 sQuotRem x y (x `quotRem'` y)) | x <- iUBs, y <- iUBs]
  where divMod'  x y = if y == 0 then (0, x) else x `divMod`  y
        quotRem' x y = if y == 0 then (0, x) else x `quotRem` y
        mkTest (nm, x, y, t) = "genQRems.arithmetic-" ++ nm ++ "." ++ x ++ "_" ++ y  ~: assert t
        mkThm2 op x y (e1, e2) = isThm $ do [a, b] <- mapM free ["x", "y"]
                                            constrain $ a .== literal x
                                            constrain $ b .== literal y
                                            return $ (literal e1, literal e2) .== a `op` b
        -- Haskell's divMod and quotRem overflows if x == minBound and y == -1 for signed types; so avoid that case
        noOverflow x y = not (x == minBound && y == -1)

-- Concrete test data
xsSigned, xsUnsigned :: (Num a, Enum a, Bounded a) => [a]
xsUnsigned = [minBound, 0, maxBound]
xsSigned   = xsUnsigned ++ [-1, 1]

w8s :: [Word8]
w8s = xsUnsigned

w16s :: [Word16]
w16s = xsUnsigned

w32s :: [Word32]
w32s = xsUnsigned

w64s :: [Word64]
w64s = xsUnsigned

i8s :: [Int8]
i8s = xsSigned

i16s :: [Int16]
i16s = xsSigned

i32s :: [Int32]
i32s = xsSigned

i64s :: [Int64]
i64s = xsSigned

iUBs :: [Integer]
iUBs = [-1000000] ++ [-1 .. 1] ++ [1000000]

rs :: [AlgReal]
rs = [fromRational (i % d) | i <- is, d <- dens]
 where is   = [-1000000] ++ [-1 .. 1] ++ [10000001]
       dens = [5,100,1000000]

-- Admittedly paltry test-cases for float/double
fs :: [Float]
fs = xs ++ map (* (-1)) xs
 where xs = [nan, infinity, 0, 0.5, 0.68302244, 0.5268265, 0.10283524, 5.8336496e-2, 1.0e-45]

ds :: [Double]
ds = xs ++ map (* (-1)) xs
 where xs = [nan, infinity, 0, 0.5, 2.516632060108026e-2, 0.8601891300751106, 7.518897767550192e-2, 1.1656043286207285e-2, 1.0e-323]

{-# ANN module ("HLint: ignore Reduce duplication" :: String) #-}
