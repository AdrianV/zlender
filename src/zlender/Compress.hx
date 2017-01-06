package zlender;

/*
* based on the LZW algorithm. Implementation by Adrian Veith
*/

using haxe.Int32;
using haxe.io.Bytes;

enum CompressedBytesData {
	Compressed(c: Bytes);
	Original(o: Bytes);
}

abstract CompressedBytes(CompressedBytesData) from CompressedBytesData to CompressedBytesData
{
	public var data(get, never): Bytes;
	inline function get_data() return switch this {
		case Compressed(c): return c;
		case Original(o): return o;
	};
	public inline function expand() return Compress.expand(this);
	public inline function isCompressed() : Bool return switch this {
		case Compressed(_): true;
		default: false;
	}
}

enum ExpandErrors {
	None;
	WrongCode;
	DataOverflow;
	DataMissing;
}

class Compress
{
	static public var lastError(default, null): ExpandErrors = None;

	static inline var compress_size = 2046;
	static inline var hash_size = 16384;
	#if (js || neko || php || python || lua)
	static inline var _empty: Int = null;
	#else
	static inline var _empty: Int = 0;
	#end

	static public inline function setI16(b: haxe.io.Bytes, pos: Int, v: Int): Void {
		#if neko
		v = v & 0xFFFF;
		#end
		b.set(pos, v & 0xFF);
		b.set(pos +1, v >> 8);
	}

	static public inline function fastGetI16(b: haxe.io.BytesData, pos: Int): Int {
		return b.fastGet(pos) | (b.fastGet(pos + 1) << 8);
	}

	public static function compress(data: Bytes): CompressedBytes {
		var bitbuffer: Int32 = 0;
		var countbits = 0;
		var codelen = 9;
		var trigger = 0x201;
		var son = new haxe.ds.Vector<Int>(hash_size); 
		var res = Bytes.alloc(data.length);
		setI16(res, 2, data.length);
		var xOut = 4;
		#if bigbuffer
		var eOut = data.length - 512;
		#else
		var eOut = data.length - 6;
		#end
		var tab = new haxe.ds.Vector<Int>(compress_size - 256); 
		var tab_link = new haxe.ds.Vector<Int>(compress_size - 256); 
		var data_buf = data.getData();
		var kx: Int32 = data_buf.fastGet(0);
		var freepos = 256;
		for (ix in 1...data.length) {
			var x = data_buf.fastGet(ix);
			var hash = ((kx & 0xFFFF) * 31 + x) & (hash_size -1);
			kx = ((kx << 16) | x); 
			var y = son[hash];
			while ((y != _empty) && (tab[y - 256] != kx)) {
			  y = tab_link[y-256];
			}
			if (y != _empty) {
			  kx = y;
			} else {
				bitbuffer = ((bitbuffer << codelen) | (kx >>> 16)); 
				countbits += codelen;
				if (countbits >= 16) {
					countbits -= 16;
					if (xOut >= eOut) {
						return Original(data);
					}
					setI16(res, xOut, bitbuffer >>> countbits);
					xOut += 2;
				}
				if (freepos <= compress_size) {
					tab[freepos - 256] = kx;
					tab_link[freepos - 256] = son[hash];
					son[hash] = freepos;
					freepos++;
					if (freepos == trigger) {
						codelen++;
						trigger = ((trigger & 0xFFFFFFF0) << 1) + 1;
					}
				}
			}
		}
		bitbuffer = ((bitbuffer << codelen) | (kx & 0xFFFF)); 
		countbits+= codelen;
		if (countbits >= 16) {
			countbits -= 16;
			#if false
			if (xOut >= eOut) {
				return Original(data);
			}
			#end
			setI16(res, xOut, bitbuffer >>> countbits);
			xOut += 2 ;
		}
		kx = xOut; 
		if (countbits != 0) {
			setI16(res, xOut, bitbuffer << (16-countbits));
			if (countbits <= 8) {
			  kx++;
			} else
			  kx += 2;
		}
		setI16(res, 0, kx);
		kx += (kx & 1);
		var result = Bytes.alloc(kx);
		result.blit(0, res, 0, kx);
		return Compressed(result);
	}
	
	static public function expand(buf: CompressedBytes): Bytes {
		switch buf {
			case Original(data): return data;
			case Compressed(data):
				var bIn = data.getData();
				#if hl
				var bufIn = bIn.bytes;
				#end
				inline function getI16(i) {
					#if hl
					return bufIn.getUI16(i);
					#else
					return fastGetI16(bIn, i);
					#end
				}
				var ebIn: Int = getI16(0);
				var bitbuffer = 0;
				var codelen = 9;
				var codemask = 0x1FF; // 9 bits set
				var ebOut: Int = getI16(2);
				var res = Bytes.alloc(ebOut);
				var res_buf = res.getData();
				#if hl
				var buf = res_buf.bytes;
				#end
				inline function buf_get(i) {
					#if hl
					return buf[i];
					#else
					return res_buf.fastGet(i);
					#end
				}
				inline function buf_put(i, v) {
					#if hl 
					buf[i] = v;
					#elseif (cpp || cs || java || flash)
					res_buf[i] = v;
					#else
					res.set(i, v);
					#end
				}
				var tab_link = new haxe.ds.Vector<Int>(compress_size);
				var tab_start = new haxe.ds.Vector<Int>(compress_size);
				for (i in 0...256) tab_link[i] = 1;
				var freepos = 256;
				var bitbuffer: Int32 = getI16(4);
				var xIn = 6;
				var countbits = 16 - 9;
				var lastk = (bitbuffer >>> countbits) & codemask;
				buf_put(0, lastk);
				var xOut2 = 0;
				var bOut = 1;
				var trigger = 0x200;
				while (true) {
					if (countbits < codelen) { 
						if (xIn < ebIn) {
							bitbuffer = ((bitbuffer << 16) | getI16(xIn)); 
							xIn += 2;
							countbits += 16;
						} else {
							break;
						}
					}
					tab_start[freepos] = xOut2;
					xOut2 = bOut;
					countbits -= codelen;
					var k = (bitbuffer >>> countbits) & codemask;
					if (k >= 256) {
						inline function movePattern(iStart, delta) {
							if (#if (cpp || cs || java || hl ) true #else false #end) //delta < 16
								while (delta > 0) {
									buf_put(bOut, buf_get(iStart));
									bOut++;
									iStart++;
									delta--;
								}
							else {
								res.blit(bOut, res, iStart, delta);
								bOut += delta;
							}
							
						}
						if (k < freepos) {
							movePattern(tab_start[k], tab_link[k]);
						} else if (k == freepos) {
							if (lastk < 256) {
								buf_put(bOut, lastk);
								bOut++;
								buf_put(bOut, lastk);
								bOut++;
							} else {
								movePattern(tab_start[lastk], tab_link[lastk]);
								buf_put(bOut, buf_get(tab_start[lastk]));
								bOut++;
								
							}
						} else { 
							lastError = WrongCode;
							return null; 
						}
					} else {
						if (bOut < ebOut) {
							buf_put(bOut, k);
							bOut++;
						} else {
							if (xIn <= ebIn) {
								lastError = DataOverflow;
								return null; 
							} else 
								return res;
						}
					}
					if (freepos <= compress_size) {
						tab_link[freepos] = tab_link[lastk] + 1;
						lastk = k;
						freepos++;
						if (freepos == trigger) {
							codelen++;
							trigger = trigger << 1;
							codemask = (codemask << 1) | 1;
						}
					} else {
						lastk = k;
					}
				}
				if (bOut == ebOut) {
					lastError = None;
					return res;
				} else { 
					lastError = DataMissing;
					return null; 
				}; 
		}
	}

}