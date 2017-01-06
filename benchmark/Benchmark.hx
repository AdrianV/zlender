
import haxe.io.Bytes;
import zlender.Compress;

class Benchmark {
	macro static public function run(test, start, done) {
		return macro {
            trace($start);
            var dt = haxe.Timer.stamp();
            $test;
            var dur = haxe.Timer.stamp() - dt;
            trace($done);
		}
	}

    static function compressLoop(data: Bytes, count: Int) {
        var c: CompressedBytes = null;
        for (i in 0... count) {
            c = Compress.compress(data);
        }
        return c;
    }

    static function expandLoop(c: CompressedBytes, count: Int) {
        var data: Bytes = null;
        for (i in 0... count) {
            data = c.expand();
        }
        return data;
    }

    #if (! js) 
    static function zcompressLoop(data: Bytes, count: Int) {
        var c: Bytes = null;
        for (i in 0... count) {
            c = haxe.zip.Compress.run(data, 9);
        }
        return c;
    }

    static function zexpandLoop(c: Bytes, count: Int) {
        var data: Bytes = null;
        for (i in 0... count) {
            data = haxe.zip.Uncompress.run(c);
        }
        return data;
    }
    #end

    public static function main() {
        var times = 10000;
        var mb = 8192 * times / (1024 * 1024);
        var data = testtools.TxtNumbers.fillRandom(8192);
        var c: CompressedBytes = null;
        run(c = compressLoop(data, times), 'compress random data:', 'in $dur speed ${mb/dur} MB/s');
        trace(c.data.length);
        var expanded: Bytes = null;
        run(expanded = expandLoop(c, times), 'expand random data:', 'in $dur speed ${mb/dur} MB/s');
        trace(expanded.length);
        trace(expanded.compare(data));
        #if (! js) 
        var cz: Bytes = null;
        run(cz = zcompressLoop(data, times), 'zip random data:', 'in $dur speed ${mb/dur} MB/s');
        run(expanded = zexpandLoop(cz, times), 'unzip random data:', 'in $dur speed ${mb/dur} MB/s');
        #end
    }
    
}