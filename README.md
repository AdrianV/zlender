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

## benchmark

timings where made on my notebook with a core i7-5700HQ

with *random* data:

*higher numbers are better*

|target|compression speed|decompression speed|zip   |unzip |inflate|
|------|----------------:|------------------:|-----:|-----:|------:|
|node js     |11.10 MB/sec |17.84 MB/sec     |
|neko 32bit  |12.20 MB/sec |27.06 MB/sec     |28.33 |113.55|3.13
|luajit      |12.73 MB/sec |45.88 MB/sec
|cpp (vcc 32)|108.66 MB/sec|186.27 MB/sec    |86.92 |98.81 |30.50
|cpp (vcc 64)|121.38 MB/sec|190.59 MB/sec    |95.88 |123.50|38.12
|cppia       |6.07 MB/sec  |11.67 MB/sec     
|cppia -jit  |44.11 MB/sec |fails     
|cs          |124.75 MB/sec|360.17 MB/sec    |
|java        |128.07 MB/sec|293.70 MB/sec    |79.55 |119.09|49.50
|hl interp   |46.31 MB/sec |116.60 MB/sec
|hl (gcc 32) |105.59 MB/sec|312.00 MB/sec


with *const* data:

*higher numbers are better*

|target|compression speed|decompression speed|zip   |unzip |inflate|
|------|----------------:|------------------:|-----:|-----:|------:|
|node js     |16.66 MB/sec |53.80 MB/sec     |
|neko 32bit  |15.73 MB/sec |74.61 MB/sec     |28.33  |113.55|
|luajit      |23.14 MB/sec |71.34 MB/sec
|cpp (vcc 32)|134.80 MB/sec|284.02 MB/sec    |192.88 |125.09|59.37
|cpp (vcc 64)|162.85 MB/sec|254.76 MB/sec    |221.50 |145.69|
|cppia       |7.14 MB/sec  |18.29 MB/sec     
|cppia -jit  |53.63 MB/sec |fails
|cs          |166.68 MB/sec|625.51 MB/sec    |
|java        |178.77 MB/sec|554.07 MB/sec    |76.97 |42.36|121.87
|hl interp   |57.95 MB/sec |208.33 MB/sec
|hl (gcc 32) |168.28 MB/sec|694.11 MB/sec


# conclusion

zlender is very light weight compression/decompression algorithm written in pure Haxe without
any outside dependencies. It is available on all tested targets and even on interpreted 
targets its speed is decent. On native targets it can outperform zip.
