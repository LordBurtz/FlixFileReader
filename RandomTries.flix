
mod File {
    pub def readLines(file: File, _: Encoding): Result[IOError, List[String]] \ IO =
        region rc {
            forM (
                len <- File.length(file);
                arrLen <- Int64.tryToInt32(len) |> Option.toOk(IOError.Generic(""));
                arr <- Ok(Array.new(rc, arrLen));
                _ <- File.readFully!(arr, file)
            ) yield arr 
                |> arrAsChar 
                |> List.subgroupBy(x -> x == '\n')
                |> List.map(line -> List.fold(List.map(Char.toString, line)))
                |> List.map(line -> line + "++\n")
                |> debug!
        }

    def arrAsChar(arr: Array[Int8, rc]): List[Char] \ rc =
        region local {
            let result = Array.map(local, Encoding.int8asAscii, arr);
            Array.toList(result) 
            |> List.filterAndLiftOption
        }

    
}

mod List {

    pub def appendOne(list: List[t], item: t): List[t] = list ::: (item :: Nil)

    // maps a List[Option[a]] to List[a]
    // filters out None
    pub def filterAndLiftOption(list: List[Option[t]]): List[t] = match list {
        case Nil => Nil,
        case Some(v) :: xs => v :: List.filterAndLiftOption(xs),
        case _ :: xs => List.filterAndLiftOption(xs)
    }

    // maps a List[a] to a List[b] using f
    // if predicate pred is satisfied
    pub def filterAndMap(pred: a -> Bool, f: a -> b, lst: List[a]): List[b] = match lst {
        case Nil => Nil,
        case x :: xs if pred(x) => f(x) :: List.filterAndMap(pred, f, xs),
        case _ :: xs => List.filterAndMap(pred, f, xs)
    }

    // splits a List[a] into a list of subgroups: List[List[a]]
    // if the predicate is satisfied by omitting the delimiter
    pub def subgroupBy(pred: a -> Bool, list: List[a]): List[List[a]] = List.splitAllOn(pred, list, Nil)

    def splitAllOn(pred: a -> Bool, list: List[a], curr: List[a]): List[List[a]] = match list {
        case Nil => Nil,
        case x :: xs if pred(x) => List.point(curr) ::: List.splitAllOn(pred, xs, Nil)
        case x :: xs => List.splitAllOn(pred, xs, List.appendOne(curr, x))
    }
}

def testReadLines(): Result[IOError, Int32] \ IO = 
    forM(
        file <- File.open("utf8.test", File.Mode.ReadOnly);
        _ <- File.readLines(file, Encoding.US_ASCII)
    ) yield 1
    

