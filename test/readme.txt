Running these tests is simple thanks to GHUnit. Just change the target in Xcode for testing on iPhone/Mac OS (should be identical, really).

The only thing is that GHUnit doesn't seem to be ARC-supported for Mac OS, so there's some memory leakage with SBJson, which is ARC-only. This shouldn't be relevant for the purposes of these tests, though, so it doesn't really matter.