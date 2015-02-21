package de.polygonal.ds;
import haxe.ds.IntMap;

/*class Slot
{
	public var index(default, null):Int;
	public function new()
	{
	}
}*/

//full state
// [1,2,3,4,-1] next
// [0,1,2,3, 4] data

//remove 0

// f=0
//[-1,2, 3, 4, -1]
//[f, 1, 2, 3, 4]

class FreeList<T> implements Collection<T>
{
	var mNext:Vector<Int>;
	var mData:Vector<T>;
	var mFree:Int;
	var mCapacity:Int;
	var mSize:Int;
	
	public var key:Int;
	
	#if debug
	var set:IntMap<Bool>;
	#end
	
	public function new(capacity:Int)
	{
		mNext = new Vector<Int>(capacity);
		for (i in 0...capacity - 1) mNext[i] = i + 1;
		mNext[capacity - 1] = -1;
		
		mData = new Vector<T>(capacity);
		mFree = 0;
		
		#if debug
		set = new IntMap<Bool>();
		#end
	}
	
	public function add(x:T):Int
	{
		if (++mSize > mCapacity)
		{
			//grow
			//create new array, gather existing values..
		}
		
		//if (mSize > MAX_SIZE
		
		var i = mFree;
		mFree = mNext[i];
		mData[i] = x;
		
		#if debug
		!set.exists(i);
		set.set(i, true);
		#end
		
		return i;
	}
	
	public function clr(slot:Int):Bool
	{
		#if debug
		set.exists(slot);
		set.remove(slot);
		#end
		
		//TODO shrink
		
		mData[slot] = null;
		mNext[slot] = mFree;
		mFree = slot;
		
		return true;
	}
	
	
	
	
	public function free():Void 
	{
		
	}
	
	public function contains(x:T):Bool 
	{
		return false;
	}
	
	public function remove(x:T):Bool
	{
		return true;
	}
	
	public function clear(purge:Bool = false):Void 
	{
		
	}
	
	public function iterator():Itr<T> 
	{
		return null;
	}
	
	public function isEmpty():Bool 
	{
		return false;
	}
	
	public function size():Int 
	{
		return mSize;
	}
	
	public function toArray():Array<T> 
	{
		return [];
	}
	
	public function toVector():Vector<T> 
	{
		return new Vector<T>(mSize);
	}
	
	public function clone(assign:Bool = true, copier:T -> T = null):Collection<T> 
	{
		return null;
	}
	
	//inline function _get(i:Int) return mA[i];
	
	//inline function _set(i:Int, x:T) mA[i] = x;
}