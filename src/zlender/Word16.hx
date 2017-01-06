package zlender;
import haxe.Int32;
import haxe.io.BytesData;

/**
 * ...
 * @author 
 */

using haxe.io.Bytes;

abstract Word16(Int32) from Int to Int from Int32 to Int32{

	public inline function new(lo: Int, hi: Int) this = ((hi & 0xFF) << 8) | (lo & 0xFF);
	public var lo(get, set): Int;
	public var hi(get, set): Int;
	
	inline function get_lo(): Int return this & 0xFF;
	inline function set_lo(v: Int) {
		this = (this & 0xFF00) | (v & 0xFF);
		return v;
	}
	
	inline function get_hi(): Int return (this >> 8) & 0xFF;
	inline function set_hi(v) {
		this = ((v & 0xFF) << 8 ) | (this & 0xFF);
		return v;
	}
	static public inline function setI16(b: Bytes, pos: Int, v: Word16) {
		#if neko
		v = v & 0xFFFF;
		#end
		b.set(pos, v);
		b.set(pos +1, v >> 8);
	}
	static public inline function getI16(b: Bytes, pos: Int): Word16 return b.get(pos) | (b.get(pos + 1) << 8);
	static public inline function fastGetI16(b: BytesData, pos: Int): Word16 return b.fastGet(pos) | (b.fastGet(pos + 1) << 8);
}
