
-- Do these really not already have an implementation on hackage?

module Control.Monad.Par.AList 
 (
  AList(..), 
  empty, singleton, cons, head, tail, length, append,
  toList, fromList,
--  parMapM, parBuild, parBuildM,
  alist_tests
 )
where 

import Test.HUnit
import Prelude hiding (length,head,tail)
import qualified Prelude as P


data AList a = ANil | ASing a | Append (AList a) (AList a) | AList [a]

instance Show a => Show (AList a) where 
  show al = "fromList "++ show (toList al)

append :: AList a -> AList a -> AList a
append ANil r = r
append l ANil = l -- **
append l r    = Append l r

{-# INLINE empty #-}
{-# INLINE singleton #-}
{-# INLINE fromList #-}

empty     ::        AList a
singleton ::  a  -> AList a
fromList  :: [a] -> AList a

empty     = ANil
singleton = ASing
fromList  = AList

-- If we tracked length perhaps this could make an effort at balance.
cons :: a -> AList a -> AList a 
cons x ANil = ASing x
cons x al   = Append (ASing x) al

-- Alas there are an infinite number of representations for null:
head :: AList a -> a 
head al = 
  case loop al of
    Just x -> x 
    Nothing -> error "cannot take head of an empty AList"
 where 
  loop al =
   case al of 
     Append l r -> case loop l of 
		     x@(Just _) -> x
		     Nothing    -> loop r
     ASing x     -> Just x
     AList (h:_) -> Just h
     AList []    -> Nothing
     ANil        -> Nothing

tail :: AList a -> AList a 
tail al = 
  case loop al of
    Just x -> x 
    Nothing -> error "cannot take tail of an empty AList"
 where 
  loop al =
   case al of 
     Append l r -> case loop l of 
		     (Just x) -> Just (Append x r)
		     Nothing  -> loop r

     ASing x     -> Just ANil
     AList (_:t) -> Just (AList t)
     AList []    -> Nothing
     ANil        -> Nothing

length :: AList a -> Int
length ANil         = 0
length (ASing _)    = 1
length (Append l r) = length l + length r
length (AList  l)   = P.length l 

toList :: AList a -> [a]
toList a = go a []
 where go ANil         rest = rest
       go (ASing a)    rest = a : rest
       go (Append l r) rest = go l $! go r rest
       go (AList xs)   rest = xs ++ rest

-- toList :: AList a -> [a]
-- toList al = loop al []
--  where 
--   loop  ANil     (h:t)   = loop h t
--   loop (ASing x) (h:t)   = x : loop h t
--   loop (AList l) (h:t)   = l ++ loop h t
--   loop (Append l r) rest = loop l (r:rest)
--   loop  ANil     []      = []
--   loop (ASing x) []      = [x]
--   loop (AList l) []      = l 


-- TODO: Provide a strategy for @par@ execution:

--------------------------------------------------------------------------------
-- Testing

-- For testing:
bintree 0 x = x
bintree n x = Append sub sub
 where sub = bintree (n-1) x

showDbg ANil         = "_"
showDbg (ASing x)    = show x
showDbg (Append l r) = "("++showDbg l++" | "++showDbg r++")"
showDbg (AList  l)   = show l

alist_tests :: Test
alist_tests = 
  TestList 
    [

      8   ~=? (length$ tail$ tail$ fromList [1..10])
    , 1   ~=? (length$ tail$tail$  cons 1$ cons 2$ cons 3 empty)

    , 253 ~=? (length$ tail$tail$tail$ bintree 8 $ singleton 'a')
    , 0   ~=? (length$ bintree 8 $ empty)

    , "((1 | 1) | (1 | 1))" ~=? (showDbg$            bintree 2 $ singleton 1)
    , "((_ | 1) | (1 | 1))" ~=? (showDbg$ tail$      bintree 2 $ singleton 1)
    , "(_ | (1 | 1))"       ~=? (showDbg$ tail$tail$ bintree 2 $ singleton 1)

    ]

t = runTestTT alist_tests


-- TODO: Quickcheck.