module Web.Scotty.Util
    ( lazyTextToStrictByteString
    , strictByteStringToLazyText
    , setContent
    , setHeaderWith
    , setStatus
    , mkResponse
    , replace
    , add
    ) where

import Network.Wai

import Network.HTTP.Types

import qualified Data.ByteString as B
import qualified Data.Text.Lazy as T
import qualified Data.Text.Encoding as ES

import Web.Scotty.Types

lazyTextToStrictByteString :: T.Text -> B.ByteString
lazyTextToStrictByteString = ES.encodeUtf8 . T.toStrict

strictByteStringToLazyText :: B.ByteString -> T.Text
strictByteStringToLazyText = T.fromStrict . ES.decodeUtf8

setContent :: Content -> ScottyResponse -> ScottyResponse
setContent c sr = sr { srContent = c }

setHeaderWith :: ([(HeaderName, B.ByteString)] -> [(HeaderName, B.ByteString)]) -> ScottyResponse -> ScottyResponse
setHeaderWith f sr = sr { srHeaders = f (srHeaders sr) }

setStatus :: Status -> ScottyResponse -> ScottyResponse
setStatus s sr = sr { srStatus = s }

-- Note: we currently don't support responseRaw, which may be useful
-- for websockets. However, we always read the request body, which
-- is incompatible with responseRaw responses.
mkResponse :: ScottyResponse -> Response
mkResponse sr = case srContent sr of
                    ContentBuilder b  -> responseBuilder s h b
                    ContentFile f     -> responseFile s h f Nothing
                    ContentStream str -> responseStream s h str
    where s = srStatus sr
          h = srHeaders sr

-- Note: we assume headers are not sensitive to order here (RFC 2616 specifies they are not)
replace :: (Eq a) => a -> b -> [(a,b)] -> [(a,b)]
replace k v m = add k v $ filter ((/= k) . fst) m

add :: (Eq a) => a -> b -> [(a,b)] -> [(a,b)]
add k v m = (k,v):m
