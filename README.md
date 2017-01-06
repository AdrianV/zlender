# zlender

zlender is a small and fast data compression and decompression library. 
It is basically a LZW like algorithm optimized for small data blocks about 8 KB.

Unlike other implementations I am aware of, the compressed data consists of a stream of 16bit words,
where the first word is the length of the compressed data and the second word is the length of the 
original data. 

If the compressed data would be larger than the original data, the original data is returned.
Because of this extra payload, this implementation is not usable for small strings.

If the expansions fails due to corrupted data, `null` is returned and the error reason is in 
`Compress.lastError`.

Usage:

```haxe

		var s = "ababaabaabababa1234567abababbbababa";
		var bs = haxe.io.Bytes.ofString(s);
		var c = zlender.Compress.compress(bs);
		trace(bs.length); 
		trace(c.data.length);
		var ed = c.expand();
		trace(bs.compare(ed));
        
```

