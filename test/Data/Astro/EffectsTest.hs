module Data.Astro.EffectsTest
(
  tests
)

where


import Test.Framework (testGroup)
import Test.Framework.Providers.HUnit
import Test.Framework.Providers.QuickCheck2 (testProperty)
import Test.HUnit
import Test.QuickCheck

import Control.Monad (unless)

import Data.Astro.TypesTest (testDecimalDegrees)
import Data.Astro.CoordinateTest (testEC1, testEcC)

import Data.Astro.Types (DecimalDegrees(..), DecimalHours(..), fromDMS, fromHMS)
import Data.Astro.Time.JulianDate (JulianDate(..))
import Data.Astro.Time.Epoch (b1950)
import Data.Astro.Coordinate (EquatorialCoordinates1(..), EclipticCoordinates(..))
import Data.Astro.Effects

tests = [testGroup "refraction" [
            testDecimalDegrees "19.33"
                0.000001
                (DD 0.045403)
                (refract (DD 19.334345) 13 1008)
            , testDecimalDegrees "horizon"
                0.000001
                (DD 0.566569)
                (refract (DD 0) 12 1013)
            , testDecimalDegrees "azimuth"
                0.000001
                (DD 0)
                (refract (DD 90) 12 1012)
            , testDecimalDegrees "azimuth"
                0.000001
                (DD 0.007905)
                (refract (DD 63.5) 15.5 1012)
            ]
         , testGroup "precession" [
             testEC1 "low-precision method"
                 0.0000001
                 (EC1 (fromDMS 14 16 7.8329) (fromHMS 9 12 20.4707))
                 (precession1 B1950 (EC1 (fromDMS 14 23 25) (fromHMS 9 10 43)) (JD 2444057.2985))
             , testEC1 "rigorous method"
                 0.0000001
                 (EC1 (fromDMS 14 16 6.3489) (fromHMS 9 12 20.4458))
                 (precession2 b1950 (EC1 (fromDMS 14 23 25) (fromHMS 9 10 43)) (JD 2444057.2985))
             ]
          , testGroup "nutation" [
              testDecimalDegrees "Longitude at 1988-09-01 00:00:00"
                  0.0000000001
                  (DD 0.0015258101)
                  (nutationLongitude (JD 2447405.5))
              , testDecimalDegrees "Obliquity at 1988-09-01 00:00:00"
                  0.0000000001
                  (DD 0.0025670999)
                  (nutationObliquity (JD 2447405.5))
              , testDecimalDegrees "Longitude at 2016-08-12 00:00:00"
                  0.0000000001
                  (DD (-0.0009839730))
                  (nutationLongitude (JD 2457612.5))
              , testDecimalDegrees "Obliquity at 2016-08-12 00:00:00"
                  0.0000000001
                  (DD (-0.0024250649))
                  (nutationObliquity (JD 2457612.5))
              ]
            , testGroup "aberration" [
                testEcC "Mars at 1988-09-08"
                  0.00000001
                  (EcC (-(fromDMS 1 32 56.3319)) (fromDMS 352 37 30.4521))
                  (includeAberration (EcC (-(fromDMS 1 32 56.4)) (fromDMS 352 37 10.1)) (JD 2447412.5) (fromDMS 165 33 44.1))
                ]
        ]

testPairOfDD msg eps expected actual =
  testCase msg $ assertPairOfDD eps expected actual

assertPairOfDD eps expected@((DD e1), (DD e2)) actual@((DD a1), (DD a2)) =
  unless (abs(e1-a1) <= eps && abs(e2-a2) <= eps) (assertFailure msg)
  where msg = "expected: " ++ show expected ++ "\n but got: " ++ show actual ++
              "\n (maximum margin of error: " ++ show eps ++ ")"
