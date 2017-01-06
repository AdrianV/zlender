package testtools;
import haxe.io.Bytes;

/**
 * ...
 * @author 
 */

class TxtNumbers
{

	static var Number1 = [
		"zero", "one", "two", "three", "four", "five",
		"six", "seven", "eight", "nine", "ten", "eleven",
		"twelve", "thirteen", "fourteen", "fifteen", "sixteen",
		"seventeen", "eighteen", "nineteen" ];
		
	static var Number9  = [
		"", " one", " two", " three", " four", " five",
		" six", " seven", " eight", " nine"];

	static var Number10 = [
		"zero", "ten", "twenty", "thirty", "fourty", "fifty",
		"sixty", "seventy", "eighty", "ninety"];
		
	
	var result: StringBuf;
	inline function new() {
		result = new StringBuf();
	}
	
	private function doNumberToText(n: Int): String {
		
		if (n > 0) {
			var dig: Int = Std.int(n / 1000);
			var h = n % 1000;
			if (dig > 0) {
			  if (h > 0) {
				HundredsToText(dig);
				result.add(" thousand ");
				HundredsToText(h);
			  } else {
				HundredsToText(dig);
				result.add(" thousand");
			  }	
			} else {
			  HundredsToText(h);
			}
		} else {
			result.add(Number1[0]);
		}
		return result.toString();		
	}
	
	function TensToText(dig: Int) {
		if (dig > 0) {
			if (dig >= 20) {
				var x = dig % 10;
				if ( x != 0) {
					result.add(Number10[Math.floor(dig / 10)]);
					result.add(Number9[x]);
				} else {
					result.add(Number10[Math.floor(dig / 10)]);
				}
			} else {
				result.add(Number1[dig]);
			}
		}
	}
	
	function HundredsToText(dig: Int) {
		if (dig > 0) {
		  var t = dig % 100;
		  var h: Int = Math.floor(dig / 100);
		  if (h > 0) {
			if (t > 0) {
			  TensToText(h);
			  result.add(" houndred ");
			  TensToText(t);
			} else {
			  TensToText(h);
			  result.add(" houndred");
			}
		  } else {
			TensToText(t);
		  }
		}
	}
	
	public static inline function NumberToText(n: Int): String {
		return new TxtNumbers().doNumberToText(n);
	}
	
	public static function fillRandom(size: Int): Bytes {
		var res = Bytes.alloc(size);
		var count = 0;
		while (count < size) {
			var s = NumberToText(Math.floor(Math.random() * 999999));
			var buf = Bytes.ofString(s);
			var x = (buf.length <= size - count) ? buf.length : size - count;
			res.blit(count, buf, 0,  x);
			count += x;
		}
		return res;
	}

	public static function fillConst(value: Int, size: Int): Bytes {
		var res = Bytes.alloc(size);
		var count = 0;
		if (value < 0) value = Math.floor(Math.random() * 999999);
		var s = NumberToText(value);
		var buf = Bytes.ofString(s);
		while (count < size) {
			var x = (buf.length <= size - count) ? buf.length : size - count;
			res.blit(count, buf, 0,  x);
			count += x;
		}
		return res;
	}
	
}